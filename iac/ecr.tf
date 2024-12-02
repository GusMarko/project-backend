# ecr 
resource "aws_ecr_repository" "ecr" {
  name = "spotify-lambda-images-ecr"
}

# policy allowing push and pull images 
resource "aws_ecr_repository_policy" "ecr_policy" {
  repository = aws_ecr_repository.ecr.name

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowPushPull",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ecr:*"
      ]
    }
  ]
}
EOF
}