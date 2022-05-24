module "ftp_server" {
  source = "./modules/ftp_server"
  dynamodb_table_name = module.dynamodb.dynamodb_table_id
}

module "dynamodb" {
  source = "./modules/dynamodb"

  dynamodb-name    = var.dynamodb-name
  read-capacity    = var.read-capacity
  write-capacity   = var.write-capacity
  hash-key         = var.hash-key
  application-name = var.application-name
  environment      = var.environment
}