variable "bucket_name" {
  description = "Назва S3-бакета для стейтів (глобально унікальна)"
  type        = string
}

variable "table_name" {
  description = "Назва DynamoDB-таблиці для блокування стейтів"
  type        = string
  default     = "terraform-locks"
}

variable "force_destroy" {
  description = "Дозволити видалення бакета разом з усіма версіями об'єктів"
  type        = bool
  default     = true
}
