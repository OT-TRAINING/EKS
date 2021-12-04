locals {
  node-userdata-ondemand = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks_cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks_cluster.certificate_authority[0].data}' --kubelet-extra-args "--node-labels=node.kubernetes.io/lifecycle=normal" '${var.cluster_name}'
USERDATA
}


resource "aws_launch_configuration" "on_demand_worker_instance" {
  for_each                    = var.create_node_group ? var.node_groups : {}
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.worker_role_profile.name
  image_id                    = data.aws_ssm_parameter.cluster.value
  instance_type               = each.value.instance_type
  key_name                    = each.value.ssh_key
  name_prefix                 = substr(each.key, 0, 12)
  security_groups             = [aws_security_group.worker-node.id]
  user_data_base64            = base64encode(local.node-userdata-ondemand)
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

resource "aws_autoscaling_group" "on_demand_node_autoscaling_group" {
  for_each             = var.create_node_group ? var.node_groups : {}
  desired_capacity     = each.value.desired_capacity
  launch_configuration = aws_launch_configuration.on_demand_worker_instance[each.key].id
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
