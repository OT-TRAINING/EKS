provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}

locals {
  common_tags        = { ENV : "QA", OWNER : "DEVOPS", PROJECT : "CATALOG_MIGRATION", COMPONENT : "EKS", COMPONENT_TYPE : "BUILDPIPER" }
  worker_group1_tags = { "name" : "worker01" }
  worker_group2_tags = { "name" : "worker02" }
}

module "eks_cluster" {
  source                       = "./eks"
  cluster_name                 = var.cluster_name
  eks_cluster_version          = "1.16"
  subnets                      = ["subnet-b55****", "subnet-ecf****"]
  tags                         = local.common_tags
  kubeconfig_name              = "config"
  config_output_path           = "config"
  eks_node_group_name          = var.eks_node_group_name
  region                       = "ap-south-1"
  endpoint_private             = false
  endpoint_public              = true
  create_spot_node_group       = true
  create_node_group            = true
  create_config_map            = true
  metrics_server               = false
  k8s-spot-termination-handler = false
  cluster_autoscaler           = false
  vpc_id                       = var.vpc_id
  slackUrl                     = "https://hooks.slack.com/services/*********/****************"
  node_groups = {
    "worker1" = {
      subnets            = ["subnet-b554*****", "subnet-ecf*****"]
      ssh_key            = var.ssh_key
      security_group_ids = [module.eks_internal_ssh_security_group.sg_id]
      instance_type      = "m5a.2xlarge"
      desired_capacity   = 3
      disk_size          = 100
      max_capacity       = 10
      min_capacity       = 2
      tags               = merge(local.common_tags, local.worker_group1_tags)
    }
  }
  spot_node_group = {
    "spot_worker-eks1" = {
      subnets            = ["subnet-b554****", "subnet-ecf****"]
      instance_type      = "m5a.2xlarge"
      disk_size          = 100
      desired_capacity   = 3
      max_capacity       = 10
      min_capacity       = 2
      ssh_key            = var.ssh_key
      spot_price         = "0.1357"
      security_group_ids = [module.eks_internal_ssh_security_group.sg_id]
      tags               = merge(local.common_tags, local.worker_group1_tags)
    }
  }
}
