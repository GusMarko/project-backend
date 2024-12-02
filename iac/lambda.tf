# lambda role
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# POLICIES FOR RESOURCES ACCESS / USING AWS PREDEFINED POLICIES
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ecr_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}



# main lambda resource 
resource "aws_lambda_function" "lambda" {
  function_name = "spotify_lambda"
  package_type  = "Image"
  image_uri     = var.image_uri
  role          = aws_iam_role.lambda_role.arn
  timeout       = 10
  memory_size   = 128

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.dynamodb.name
      REGION              = var.aws_region
    }
  }

  tags = {
    Name        = "spotify_lambda"
    Environment = "${var.env}"
  }
}



# lambda permission for api gateway invoke
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.spotify_api.execution_arn}/*/*"
}
