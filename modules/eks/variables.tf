variable "cluster_name" {
  description = "Назва EKS-кластера"
  type        = string
}

variable "cluster_version" {
  description = "Версія Kubernetes (null — остання доступна в EKS)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Підмережі для кластера та нод (приватні підмережі VPC)"
  type        = list(string)
}

variable "node_instance_type" {
  description = "Тип EC2-інстансу для нод"
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "Бажана кількість нод"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Мінімальна кількість нод"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Максимальна кількість нод"
  type        = number
  default     = 3
}