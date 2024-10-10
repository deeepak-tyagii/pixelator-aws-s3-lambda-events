env                   = "dev"
aws_region            = "us-east-1"
source_bucket_name    = "pixelator-project-source"
processed_bucket_name = "pixelator-project-processed"
iam_role              = "pixelator_role"
inline_policy_name    = "pixelator_inline_policy"
lambda_name           = "pixelator"
lambda_zip_path       = "my-deployment-package.zip"
lambda_runtime        = "python3.9"