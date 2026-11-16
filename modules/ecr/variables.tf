variable "ecr_name" {
  description = "Назва ECR-репозиторію"
  type        = string
}

variable "scan_on_push" {
  description = "Автоматично сканувати образи на вразливості під час push"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "MUTABLE або IMMUTABLE — чи можна перезаписувати теги образів"
  type        = string
  default     = "MUTABLE"
}

variable "force_delete" {
  description = "Дозволити видалення репозиторію разом з образами"
  type        = bool
  default     = true
}
