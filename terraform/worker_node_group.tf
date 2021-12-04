data "aws_ssm_parameter" "cluster" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.eks_cluster.version}/amazon-linux-2/recommended/image_id"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.authentication.token
  load_config_file       = false
}

locals {
  node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks_cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks_cluster.certificate_authority[0].data}' --kubelet-extra-args "--node-labels=node.kubernetes.io/lifecycle=spot" '${var.cluster_name}'
USERDATA
}

resource "aws_iam_instance_profile" "worker_role_profile" {
  name = format("instance-profile-%s", var.cluster_name)
  role = aws_iam_role.node_group_role.name
}

resource "aws_launch_configuration" "worker_instance" {
  for_each                    = var.create_spot_node_group ? var.spot_node_group : {}
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.worker_role_profile.name
  image_id                    = data.aws_ssm_parameter.cluster.value
  instance_type               = each.value.instance_type
  spot_price                  = each.value.spot_price
  key_name                    = each.value.ssh_key
  name_prefix                 = substr(each.key, 0, 12)
  security_groups             = [aws_security_group.worker-node.id]
  user_data_base64            = base64encode(local.node-userdata)
  root_block_device {
    encrypted             = false
    volume_size           = each.value.disk_size
    volume_type           = "gp2"
    delete_on_termination = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "node_autoscaling_group" {
  for_each         = var.create_spot_node_group ? var.spot_node_group : {}
  desired_capacity = each.value.desired_capacity
  launch_configuration = aws_launch_configuration.worker_instance[each.key].id
  max_size             = each.value.max_capacity
  min_size             = each.value.min_capacity
  name                 = substr("${each.key}-${var.cluster_name}", 0, 12)
  vpc_zone_identifier  = each.value.subnets
  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "eks:cluster-name"
    value               = var.cluster_name
    propagate_at_launch = true
  }

  tag {
    key                 = "eks:nodegroup-name"
    value               = substr("${each.key}-${var.cluster_name}", 0, 12)
    propagate_at_launch = true
  }
}

resource "kubernetes_config_map" "aws_auth_cm" {
  count = var.create_config_map ? 1 : 0
  depends_on = [aws_eks_cluster.eks_cluster]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels = merge({
      "app.kubernetes.io/managed-by" = "Terraform"
      "terraform.io/module"          = "terraform-aws-modules.eks.aws"
    })
  }
  data = {
    mapRoles = yamlencode(
      distinct(concat(
        local.configmap_roles,
      ))
    )
  }
}
