output "dynamodb_table_id" {
  value = aws_dynamodb_table.dynamodb_table.id
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.dynamodb_table.arn
}