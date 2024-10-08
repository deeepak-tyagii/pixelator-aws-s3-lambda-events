# pixelator-aws-s3-lambda-events
An event-driven image processing pipeline using AWS Lambda and S3. When images are uploaded to a source S3 bucket, Lambda triggers and pixelates the images in five variations (8x8, 16x16, 32x32, 48x48, 64x64) using the PIL library, then stores them in a processed S3 bucket.
