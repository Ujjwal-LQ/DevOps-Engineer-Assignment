data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_role" {
  name = "ftp_server_role-${terraform.workspace}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "ftp_lambda_policy-${terraform.workspace}"
  description = "Access policy for lambda function"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : "arn:aws:secretsmanager:*:*:secret:*",
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_policy_attachement" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


resource "aws_lambda_function" "ftp_lambda_function" {
  filename         = data.archive_file.ftp_lambda_function_code.output_path
  function_name    = "${terraform.workspace}-ftp-auth-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  description      = "ftp auth lambda function"
  source_code_hash = filebase64sha256(data.archive_file.ftp_lambda_function_code.output_path)
  environment {
    variables = {
      SecretsManagerRegion = "us-east-1"
    }
  }
}

data "archive_file" "ftp_lambda_function_code" {
  type        = "zip"
  source_file = "${path.module}/../../src/ftp_lambda/lambda_function.py"
  output_path = "${path.module}/../../files/ftp_lambda.zip"
}

resource "aws_lambda_permission" "allow_transfer_service" {
  statement_id  = "AllowTransferInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ftp_lambda_function.arn
  principal     = "transfer.amazonaws.com"
  source_arn    = aws_transfer_server.ftp_server.arn
}

## dynamodb put lambda

resource "aws_iam_role" "dynamodb_lambda_role" {
  name = "dynamodb_put_lambda_role-${terraform.workspace}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "dynamodb_lambda_policy" {
  name        = "dynamodb_put_lambda_policy-${terraform.workspace}"
  description = "Access policy for lambda function"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : "${aws_s3_bucket.s3_ftp_bucket.arn}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ],
        "Resource" : "${aws_s3_bucket.s3_ftp_bucket.arn}/*",
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem"
        ],
        "Resource" : "arn:aws:dynamodb:*:*:table/${var.dynamodb_table_name}",
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_lambda_basic_execution_policy_attachement" {
  role       = aws_iam_role.dynamodb_lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_lambda_policy.arn
}


resource "aws_lambda_function" "dynamodb_ftp_lambda_function" {
  filename         = data.archive_file.dynamodb_lambda_function_code.output_path
  function_name    = "${terraform.workspace}-dynamodb-put-data-lambda"
  role             = aws_iam_role.dynamodb_lambda_role.arn
  handler          = "lambda_function.readS3file"
  runtime          = "nodejs14.x"
  description      = "dynamodb lambda function"
  source_code_hash = filebase64sha256(data.archive_file.dynamodb_lambda_function_code.output_path)
  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }
}

data "archive_file" "dynamodb_lambda_function_code" {
  type        = "zip"
  source_file = "${path.module}/../../src/dynamodb_put_data/lambda_function.js"
  output_path = "${path.module}/../../files/dynamodb_put_data.zip"
}

resource "aws_s3_bucket_notification" "dynamodb_aws_lambda_trigger" {
  bucket = aws_s3_bucket.s3_ftp_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.dynamodb_ftp_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]

  }
}
resource "aws_lambda_permission" "all_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dynamodb_ftp_lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.s3_ftp_bucket.id}"
}
