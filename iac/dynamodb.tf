# dynamodb / pay-per-request
# primary key made of artist and song name's
resource "aws_dynamodb_table" "dynamodb"{
  name = "spotify_data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "artistName"
  range_key = "songName"

   attribute {
    name = "artistName"
    type = "S" 
  }

  attribute {
    name = "songName"
    type = "S" 
  }

  tags = {
    Name = "dynamodb-spotify-data"
    Environment = "${var.env}"
  }
}