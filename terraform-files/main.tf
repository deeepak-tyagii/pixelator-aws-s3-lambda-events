# Fetch AWS Account ID
data "aws_caller_identity" "current" {}

#create the aws s3 bucket
resource "aws_s3_bucket" "pixelator_project_source" {
  bucket        = var.source_bucket_name
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = var.source_bucket_name
    Environment = var.env
  }
}

resource "aws_s3_bucket" "pixelator_project_processed" {
  bucket        = var.processed_bucket_name
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = var.processed_bucket_name
    Environment = var.env
  }
}

# Define IAM role
resource "aws_iam_role" "pixelator_role" {
  name = var.iam_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the inline policy to the IAM role
resource "aws_iam_role_policy" "pixelator_inline_policy" {
  name = var.inline_policy_name
  role = aws_iam_role.pixelator_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          format("arn:aws:s3:::%s", var.processed_bucket_name),
          format("arn:aws:s3:::%s/*", var.processed_bucket_name),
          format("arn:aws:s3:::%s/*", var.source_bucket_name),
          format("arn:aws:s3:::%s", var.source_bucket_name)
        ]
      },
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = format("arn:aws:logs:%s:%s:*", var.aws_region, data.aws_caller_identity.current.account_id)
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          format("arn:aws:logs:%s:%s:log-group:/aws/lambda/%s:*", var.aws_region, data.aws_caller_identity.current.account_id, var.lambda_name)
        ]
      }
    ]
  })
}

# Define Lambda function
resource "aws_lambda_function" "pixelator" {
  function_name = var.lambda_name
  filename = var.lambda_zip_path
  runtime  = var.lambda_runtime
  handler  = "lambda_function.lambda_handler"
  role     = aws_iam_role.pixelator_role.arn
  timeout  = 60
  environment {
    variables = {
      processed_bucket = var.processed_bucket_name
    }
  }
}

#Define the permissions to allow bucket to trigger lambda
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pixelator.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.pixelator_project_source.arn
}

# Define the S3 notification to trigger the Lambda function
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.pixelator_project_source.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.pixelator.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}