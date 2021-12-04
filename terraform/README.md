# EKS

[![Opstree Solutions][opstree_avatar]][opstree_homepage]<br/>[Opstree Solutions][opstree_homepage] 

  [opstree_homepage]: https://opstree.github.io/
  [opstree_avatar]: https://img.cloudposse.com/150x150/https://github.com/opstree.png

- This terraform module will create a EKS Cluster.
- This projecct is a part of opstree's ot-aws initiative for terraform modules.

## Usage

```hcl
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
  cluster_name                 = "cluster_name"
  eks_cluster_version          = "1.16"
  subnets                      = ["subnet-b55****", "subnet-ecf****"]
  tags                         = local.common_tags
  kubeconfig_name              = "config"
  config_output_path           = "config"
  eks_node_group_name          = "eks_node_group_name"
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

```

```sh
$   cat output.tf
/*-------------------------------------------------------*/
output "endpoint" {
  description = "Endpoint for EKS cluster"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "node_iam_role_arn" {
  description = "Worker nodes IAM Role ARN"
  value       = aws_iam_role.node_group_role.arn
}

output "cluster_iam_role_arn" {
  description = "Cluster IAM Role ARN"
  value       = aws_iam_role.cluster_role.arn
}

output "kubeconfig-certificate-authority-data" {
  description = "Kubernetes SSL certificate data"
  value       = aws_eks_cluster.eks_cluster.certificate_authority.0.data
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.eks_cluster.id
}

output "eks_cluster_arn" {
  description = "EKS resource ARN"
  value       = aws_eks_cluster.eks_cluster.arn
}

/*-------------------------------------------------------*/
```
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cluster_name | Name of Your Cluster. | string | null | yes |
| vpc_subnet | A list of subnet IDs to launch resources in. | List | null | yes |
| eks_cluster_version | Define Kubernetes Version to install. | string | null | yes |
| eks_cluster_tag | eks Cluster Tag. | map(string) | null | yes |
| node_group_name | node group name to attach in EKS. | string | null | yes |
| instance_type | Define Instance type ie. "t2.medium". | lint(string) | null | yes |
| disk_size | Define Disk size of nodes. | number | null | yes |
| scale_min_size | Define minimum nodes scaling. | number | null | yes |
| scale_desired_size | Define Desire nodes. | number | null | yes |
| ssh_key | Define ssh key. | string | null | yes |
| security_group_ids | ssh security group id for ssh. | string | null | yes |
| kubeconfig_name | name for kube config file. | string | null | yes |
| config_output_path | path to store kubeconfig file | string | null | yes |
| region | define region | string | null | yes |
| endpoint_private | define endpoint private | boolean | null | yes |
| endpoint_public | define endpoint public | boolean | null | yes |
| create_spot_node_group | if want to create spot node group | boolean | null | yes |
| create_node_group | if want to create on-demand node group | boolean | null | yes |
| create_config_map | apply aws config map for node group | boolean | yes | no |
| metrics_server | if you want to install materics server in eks cluster | boolean | yes | no |
| k8s-spot-termination-handler | if you want to install k8s-spot-termination-handler in eks cluster | boolean | yes | no |
| cluster_autoscaler | if you want to install cluster_autoscaler in eks cluster | boolean | yes | no |
| slackUrl | notification for instance termination | boolean | yes | no |


## Outputs

| Name | Description |
|------|-------------|
| endpoint | Endpoint of EKS cluster |
| node_iam_role_arn | EKS node group default arn |
| kubeconfig-certificate-authority-data | eks certificate |
| eks_cluster_id | Eks cluster id |
| eks_cluster_arn | EKS cluster arn eks_cluster_arn |

## Related Projects

Check out these related projects.

- [network_skeleton](https://gitlab.com/ot-aws/terrafrom_v0.12.21/network_skeleton) - Terraform module for providing a general purpose Networking solution
- [security_group](https://gitlab.com/ot-aws/terrafrom_v0.12.21/security_group) - Terraform module for creating dynamic Security groups
- [HA_ec2_ALB](https://gitlab.com/ot-aws/terrafrom_v0.12.21/ha_ec2_alb) - Terraform module will create a Highly available setup of an EC2 instance with quick disater recovery.
- [rds](https://gitlab.com/ot-aws/terrafrom_v0.12.21/rds) - Terraform module for creating Relation Datbase service.
- [HA_ec2](https://gitlab.com/ot-aws/terrafrom_v0.12.21/ha_ec2.git) - Terraform module for creating a Highly available setup of an EC2 instance with quick disater recovery.
- [rolling_deployment](https://gitlab.com/ot-aws/terrafrom_v0.12.21/rolling_deployment.git) - This terraform module will orchestrate rolling deployment.

### Contributors

[![Devesh Sharma][devesh_avataar]][devesh_homepage]<br/>[Devesh Sharma][devesh_homepage] 

  [devesh_homepage]: https://github.com/deveshs23
  [devesh_avataar]: https://img.cloudposse.com/150x150/https://github.com/deveshs23.png
