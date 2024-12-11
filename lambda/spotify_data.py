import boto3
import requests
import json
import os

# dynamodb connection / client
dynamodb = boto3.resource ('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME')
table = dynamodb.Table(table_name)


# setting spotify api credentials from env var of lambda
SPOTIFY_CLIENT_ID = os.environ.get('SPOTIFY_CLIENT_ID')
SPOTIFY_CLIENT_SECRET = os.environ.get('SPOTIFY_CLIENT_SECRET')
print("gave env variables")

def lambda_handler(event, context):
# Extract the artist name from the event - api gateway GET
    artist_name = event['queryStringParameters'].get('artist', '')
    print(f"took artist name , it is: {artist_name}")
# error handling
    if not artist_name:
        return build_response(400, {"error": "Artist name is required"})

# checking dynamodb for artistName hash key that matches
# IF TRUE
    songs = get_songs_from_dynamodb(artist_name)
    if songs:
        return build_response(200, {"songs": songs})
# IF FALSE 
# fetch songs from spotify api
    songs = get_songs_from_spotify(artist_name)
    if songs:
# store songs in dynamodb
        store_songs_in_dynamodb(artist_name, songs)
        print("songs stored")
        return build_response(200, {"songs": songs})
# error handling if there is no songs 
    return build_response(404, {"error": "No songs found for the given artist"})



#---------------------FUNCTIONS---------------------

# function uses query function to find data which hash key artistName matches variable artist_name
def get_songs_from_dynamodb(artist_name):
    response = table.query(
        KeyConditionExpression=boto3.dynamodb.conditions.Key('artistName').eq(artist_name)
    )
    items = response.get('Items', [])
    
    if not items: 
        return False
    
    return [item['songName'] for item in items]

# authorization with spotify and calling spotify api for 5 songs from artist / storing response in list of strings
def get_songs_from_spotify(artist_name):

        token = get_spotify_access_token()
        headers = {"Authorization": f"Bearer {token}"}
        search_url = f"https://api.spotify.com/v1/search?q={artist_name}&type=track&limit=5"
        response = requests.get(search_url, headers=headers)

        if response.status_code == 200:
            tracks = response.json().get('tracks', {}).get('items', [])
            return [track['name'] for track in tracks]
        else:
            print(f"Spotify API error: {response.text}")
            return None


# function uses batch writer to put multiple items at one using for loop, hash and range key defines objects atributes
def store_songs_in_dynamodb(artist_name, songs):
    with table.batch_writer() as batch:
        for song in songs:
             batch.put_item(
                Item={
                    'artistName': artist_name,
                    'songName': song
                }
            )


# function providing spotify token using credentials / function is used in other function not in main()
def get_spotify_access_token ():
    auth_url = "https://accounts.spotify.com/api/token"
    auth_data = {
        "grant_type": "client_credentials",
        "client_id": SPOTIFY_CLIENT_ID,
        "client_secret": SPOTIFY_CLIENT_SECRET
    }
    response = requests.post(auth_url, data = auth_data, timeout=30)

    if response.status_code == 200:
        return response.json().get("access_token")
    else:
        raise Exception(f"Providing spotify access token failed, {response.status_code}: {response.text} ")


# response function / building body of response 
def build_response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body)
    }





