# api gateway's api creation
resource "aws_api_gateway_rest_api" "spotify_api" {
  name        = "SpotifyAPI"
}

# api gateway resource
resource "aws_api_gateway_resource" "search" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  parent_id   = aws_api_gateway_rest_api.spotify_api.root_resource_id
  path_part   = "search"  
}

 #------------------- GET METHOD -----------------------------

# api GET method / cors response
resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.spotify_api.id
  resource_id   = aws_api_gateway_resource.search.id
  http_method   = "GET"
  authorization = "NONE"  
}

# integration with lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.spotify_api.id
  resource_id             = aws_api_gateway_resource.search.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn

}

 #------------------------------------------------------------------

# deployment of api
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration
    ]
}

# staging api gateway
resource "aws_api_gateway_stage" "dev_stage" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  stage_name    = "dev"


  depends_on = [aws_api_gateway_deployment.api_deployment]
}


# Handling cors response and access / pre defined module 
#module "api-gateway-enable-cors" {
#source  = "squidfunk/api-gateway-enable-cors/aws"
#version = "0.3.3"
#api_id          = "${aws_api_gateway_rest_api.spotify_api.id}"
#api_resource_id = "${aws_api_gateway_resource.search.id}"
#}

resource "aws_api_gateway_method_response" "http_200" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  resource_id = aws_api_gateway_rest_api.spotify_api.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
   }
}


resource "aws_api_gateway_integration_response" "api_gw_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  resource_id = aws_api_gateway_rest_api.spotify_api.id
  http_method = "GET"
  status_code = aws_api_gateway_method_response.http_200.status_code

  response_templates = {
    "application/json" = ""
  }
}