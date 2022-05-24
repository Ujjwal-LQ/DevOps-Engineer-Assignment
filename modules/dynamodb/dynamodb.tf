resource "aws_dynamodb_table" "dynamodb_table" {
  name           = var.dynamodb-name
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read-capacity
  write_capacity = var.write-capacity
  hash_key       = var.hash-key

  attribute {
    name = var.hash-key
    type = "S"
  }

  tags = {
    Name             = var.dynamodb-name
    application-name = var.application-name
    environment      = var.environment
  }
}