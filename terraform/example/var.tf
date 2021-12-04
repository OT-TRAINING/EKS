variable "white_listed_ips" {
  default = ["117.97.72.191/32"]
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
  default     = "non-prod-eks-cluster"
}

variable "ssh_key" {
  description = "ssh keys"
  type        = string
  default     = "buildpiper"

}
variable "kubeconfig_file_name" {
  description = "kubeconfig file name"
  type        = string
  default     = "config"
}

variable "vpc_id" {
  type    = string
  default = "vpc-******"
}

variable "kubeconfig_name" {
  type    = string
  default = "config"
}

variable "eks_node_group_name" {
  type    = string
  default = "eks2-cluster"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}
