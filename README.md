<h3 align="center">Connect with me:</h3>
<p align="center">
<div> 
  <p align="center">
    <a href="https://www.linkedin.com/in/deepaktyagi048/"><img title="https://www.linkedin.com/in/deepaktyagi048/" src="https://img.shields.io/badge/-LinkedIn-%230077B5?style=for-the-badge&logo=linkedin&logoColor=white">
    </a>
	<a href="https://www.instagram.com/deeepak.tyagi/"><img title="instagram.com/deeepak.tyagi" src="https://img.shields.io/badge/Instagram-%23E4405F.svg?style=for-the-badge&logo=Instagram&logoColor=white">
    </a>
   <a href="https://www.facebook.com/iamdeepsz"><img title="facebook.com/iamdeepz" src="https://img.shields.io/badge/Facebook-%231877F2.svg?style=for-the-badge&logo=Facebook&logoColor=white">
    </a>
   <a href="https://medium.com/@deepak-tyagi" target="_blank">
<img src=https://img.shields.io/badge/medium-%23292929.svg?&style=for-the-badge&logo=medium&logoColor=white alt=medium style="margin-bottom: 5px;" />
</a> 
  </p>
</div>
</p>

# pixelator-aws-s3-lambda-events
An event-driven image processing pipeline using AWS Lambda and S3. When images are uploaded to a source S3 bucket, Lambda triggers and pixelates the images in five variations (8x8, 16x16, 32x32, 48x48, 64x64) using the PIL library, then stores them in a processed S3 bucket.

![Architecture Diagram](pixelator-arch-diagram.gif)
---

## Stage 1: Create the S3 Buckets

Go to the [S3 Console](https://s3.console.aws.amazon.com/s3/home?region=us-east-1#). You’ll need to create two buckets in the `us-east-1` region. Each bucket will have a unique name but a similar naming structure—one for the source and one for the processed images.

- Bucket 1: `<unique-name>-source`
- Bucket 2: `<unique-name>-processed`

Example:

- Source bucket: `unique-name-source`
- Processed bucket: `unique-name-processed`

---

## Stage 2: Set Up the Lambda Execution Role

Navigate to the [IAM Console](https://console.aws.amazon.com/iamv2/home?#/home).

1. Create a new role with the type `AWS service` and choose `Lambda`.
2. Name the role `PixelatorRole`.
3. Attach an inline policy with permissions for the Lambda function to access both the source and processed buckets.

The inline policy should include the following resources, with `REPLACEME` replaced by your bucket names:

```json
"Resource": [
  "arn:aws:s3:::<your-source-bucket>",
  "arn:aws:s3:::<your-source-bucket>/*",
  "arn:aws:s3:::<your-processed-bucket>",
  "arn:aws:s3:::<your-processed-bucket>/*"
]

```
Locate the two occurrences of `YOURACCOUNTID`, you need to replace both of these words with your AWS account ID. To get that, click the account dropdown at the top right. Click the small icon to copy down the `Account ID` and replace the `YOURACCOUNTID` in the policy code editor.  **Important:** If you use the icon to copy this number, it will remove the `-` in the account number for you. You need to paste `123456789000` rather than `1234-5678-9000`.

Here's the policy you should have, only with your account ID:

```
{
  "Effect": "Allow",
  "Action": "logs:CreateLogGroup",
  "Resource": "arn:aws:logs:us-east-1:123456789000:*"
},
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ],
  "Resource": [
    "arn:aws:logs:us-east-1:123456789000:log-group:/aws/lambda/pixelator:*"
  ]
}
```

Click `Review Policy`. For name put `pixelator_access_inline` and create the policy.

# Stage 3 (pre) - ONLY DO THIS PART IF YOU WANT TO GET EXPERIENCE OF CREATING A LAMBDA ZIP (macOS/Linux Only)

This guide is only tested on macOS, it should work on Linux. Windows may require different tools. If in doubt, skip to step 3 below.

**From the CLI/Terminal:**

1. Create a folder named `my_lambda_deployment`.
2. Move into that folder (`cd my_lambda_deployment`).
3. Create a folder called `lambda`.
4. Move into that folder (`cd lambda`).
5. Create a file called `lambda_function.py` and paste in the code for the `pixelator` [Lambda function](https://github.com/deeepak-tyagii/pixelator-aws-s3-lambda-events/blob/053f2770d13142ec88b8b1dd8d567c7c3183edbd/lab-setup-files/lambda/lambda_function.py) .
6. Download this file [PIL Package](https://files.pythonhosted.org/packages/f3/3b/d7bb231b3bc1414252e77463dc63554c1aeccffe0798524467aca7bad089/Pillow-9.0.1-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl) into that folder.
7. Run `unzip Pillow-9.0.1-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl` and then `rm Pillow-9.0.1-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl`.  These are the Pillow module files required for image manipulation in Python 3.9 (which the lambda function will be using).
8. From the same folder, run `zip -r ../my-deployment-package.zip .` which will create a lambda function zip, containing all these files in the parent directory.

This zip will be the same zip which is linked below, so if you have any issues with the lambda function, you can use the one that's pre-created.

# Stage 3 - Create the Lambda Function

1. Move to the [lambda console](https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions).
2. Click `Create Function`.
3. We're going to be `Authoring from Scratch`.
4. For `Function name` enter `pixelator`.
5. For `Runtime` select `Python 3.9`.
6. For `Architecture` select `x86_64`.
7. For `Permissions` expand `Change default execution role` pick `Use an existing role` and in the `Existing role` dropdown, pick `PixelatorRole`.
8. Then `Create Function`  
9. Close down any `notifcation` dialogues/popups  
10. Click `Upload from` and select `.zip file`
11. Either 1, download this zip to your local machine [Zip-File](https://github.com/deeepak-tyagii/pixelator-aws-s3-lambda-events/blob/053f2770d13142ec88b8b1dd8d567c7c3183edbd/lab-setup-files/my-deployment-package.zip), click Download.
or 2, locate the .zip you created yourself in the `Stage 3(pre)` above - they will be identical  
12. On the lambda screen, click `Upload` locate and select that .zip, and then click the `Save` button  
13. This upload will take a few minutes, but once complete you might see something saying `The deployment package of your Lambda function "pixelator" is too large to enable inline code editing. However, you can still invoke your function.` which is OK :)  


# Stage 4 - Configure the Lambda Function & Trigger

1. Click the "Configuration" tab, then "Environment variables".
2. We need to add an environment variable telling the pixelator function which processed bucket to use. It will know the source bucket because it's told about that in the event   
 data.
3. Click "Edit", then "Add environment variable".
4. Under "Key", put `processed_bucket`.
5. For "Value", put the bucket name of **your** processed bucket. For example, `dontusethisname-processed` (but use **your** bucket name).
6. **Be extremely careful** to put your `processed` bucket here, **NOT** your source bucket. If you use the source bucket here, the output images will be stored in the source bucket, causing the lambda function to run indefinitely, which is not desirable.
7. Click "Save".
8. Click "General configuration", then "Edit".
9. Change the timeout to "1" minute and "0" seconds.
10. Click "Save".
11. Click "Add trigger".
12. In the dropdown, select "S3".
13. Under "Bucket", pick your **source** bucket. **Again**, be very careful to ensure this is your source bucket, not your destination bucket or any other bucket.
14. Check the "Recursive invocation" acknowledgment box. This is because this lambda function is invoked every time anything is added to the source bucket. If you configure this   
 incorrectly or the environment variable above incorrectly, the lambda function will run indefinitely.
15. Once checked, click "Add". 

# Stage 5 - Test and Monitor

**Open Multiple Tabs**

1. Open a tab to the [CloudWatch Logs console](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups)
2. Open two tabs to the [S3 console](https://s3.console.aws.amazon.com/s3/home?region=us-east-1)

**Upload Test Images**

3. In one S3 console tab, navigate to your **source** bucket and select the "Objects" tab.
4. Click "Upload" and add some files (use your own or the provided sample images
5. Click "Upload" again once finished adding files.

**View Logs and Processed Images:**

6. Switch to the CloudWatch Logs tab.
7. Click the "Refresh" icon and locate the log stream named `/aws/lambda/pixelator`.
8. Click the most recent log stream if available. Otherwise, keep refreshing and clicking the newest stream.
9. Expand the line starting with `{'Records': [{'eventVersion':` to see details about the lambda invocation, including the uploaded object name in `'object': {'key'}`.
10. Switch to the other S3 console tab and navigate to your **processed** bucket.
11. Click the "Refresh" icon.
12. Select each of the five pixelated image versions: `8x8`, `16x16`, `32x32`, `48x48`, and `64x64`.
13. Click "Open" for each image. Your browser will either open or download the images.
14. Open the images one by one, starting with `8x8` and progressing to `64x64`. Observe how they are the same image with increasing levels of pixelation.


## Stage 6 - Cleanup

**1. Delete Lambda Function:**

* Open the `pixelator` [lambda function](https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/pixelator?tab=code)
* Click "Delete" to remove the function.

**2. Delete IAM Role:**

* Move to the [IAM Roles console](https://console.aws.amazon.com/iamv2/home#/roles)
* Click on "PixelatorRole".
* Click "Delete" and confirm the deletion of the role.

**3. Empty and Delete S3 Buckets:**

* Go to the [S3 Console](https://s3.console.aws.amazon.com/s3/home?region=us-east-1&region=us-east-1)

**For each bucket (source and processed):**

    1. Select the bucket.
    2. Click "Empty".
    3. Type "permanently delete" and click "Empty" again to confirm.
    4. Close the dialogue and return to the main S3 Console.
    5. Ensure the bucket is still selected and click "Delete".
    6. Type the name of the bucket and confirm deletion.

**4. Completion:**

That's all! You've successfully cleaned up the resources created in this guide.

  






