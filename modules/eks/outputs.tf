output "cluster_name" {
  description = "Назва EKS-кластера"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint Kubernetes API"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Версія Kubernetes"
  value       = aws_eks_cluster.main.version
}

output "node_group_name" {
  description = "Назва групи нод"
  value       = aws_eks_node_group.main.node_group_name
}