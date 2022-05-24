resource "aws_s3_bucket" "s3_ftp_bucket" {
  bucket = "${terraform.workspace}-sftp-setup"
  tags = {
    Environment = terraform.workspace
    Maintainer  = "Terraform"
  }
}

# resource "aws_s3_bucket_public_access_block" "s3_ftp_public_access_block" {
#   bucket                  = aws_s3_bucket.s3_ftp_bucket.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

resource "aws_iam_role" "ftp_s3_access_role" {
  name = "ftp-s3-access-${terraform.workspace}"

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

resource "aws_iam_policy" "ftp_s3_access_policy" {
  name        = "ftp-s3-policy-${terraform.workspace}"
  description = "Access policy for ftp s3 access"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
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
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ftp_s3_access_policy_attachement" {
  role       = aws_iam_role.ftp_s3_access_role.name
  policy_arn = aws_iam_policy.ftp_s3_access_policy.arn
}
