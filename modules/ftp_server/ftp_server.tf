resource "aws_transfer_server" "ftp_server" {
  endpoint_type          = "PUBLIC"
  domain                 = "S3"
  protocols              = ["SFTP"]
  identity_provider_type = "AWS_LAMBDA"
  function               = aws_lambda_function.ftp_lambda_function.arn
  logging_role           = aws_iam_role.ftp_logging_role.arn
  security_policy_name   = "TransferSecurityPolicy-2020-06"
  tags = {
    Environment = terraform.workspace
    Name        = "ftp-server-${terraform.workspace}"
    Maintainer  = "terraform"
  }
}

resource "aws_iam_role" "ftp_logging_role" {
  name = "ftp_server_logging-${terraform.workspace}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "transfer.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ftp_logging_policy_attachment" {
  role       = aws_iam_role.ftp_logging_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}
