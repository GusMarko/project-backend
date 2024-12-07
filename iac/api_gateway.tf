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

# api GET method 
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

resource "aws_api_gateway_method_response" "response" {
  http_method = aws_api_gateway_method.get.http_method
  resource_id = aws_api_gateway_resource.search.id
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "response" {
  resource_id = aws_api_gateway_resource.search.id
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = aws_api_gateway_method_response.response.status_code

  response_templates = {
    "application/json" = jsonencode({"LambdaValue"="$input.path('$').body", "data" = "Custom Value"})
  }

  depends_on = [ 
    aws_api_gateway_integration.lambda_integration
   ]

   response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'"
        "method.response.header.Access-Control-Allow-Origin" = "'*'"

   }
}

# deployment of api
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.search.id,
      aws_api_gateway_method.get.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_method_response.response.id,
      aws_api_gateway_integration_response.response.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    ]
}

# Staging api gateway
resource "aws_api_gateway_stage" "dev_stage" {
  rest_api_id = aws_api_gateway_rest_api.spotify_api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  stage_name    = "dev"


  depends_on = [aws_api_gateway_deployment.api_deployment]
}
