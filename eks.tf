provider "aws" {
    region = "ap-south-1"
    profile = "default"
}
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true" 
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    
}

resource "aws_subnet" "subnet-1" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" 
    availability_zone = "ap-south-1a"
    tags {
        Name = "subnet-1"
    }
}

resource "aws_internet_gateway" "gateway" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "gateway"
    }
}

resource "aws_route_table" "route_table" {
    vpc_id = "${aws_vpc.main-vpc.id}"
    
    route {
        
        cidr_block = "0.0.0.0/0" 
        
        gateway_id = "${aws_internet_gateway.gateway.id}" 
    }
    
    tags {
        Name = "route_table"
    }
}


resource "aws_route_table_association" "route_table_association "{
    subnet_id = "${aws_subnet.subnet-1.id}"
    route_table_id = "${aws_route_table.route_table.id}"
}

resource "aws_iam_role" "my_cluster" {
  name = "terraform-eks-my_cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "my_cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.my_cluster.name
}

resource "aws_iam_role_policy_attachment" "my_cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.my_cluster.name
}

resource "aws_security_group" "my_cluster" {
  name        = "terraform-eks-my_cluster"
  vpc_id      = aws_vpc.demo.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-demo"
  }
}

resource "aws_security_group_rule" "my_cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.my_cluster.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "demo" {
  name     = var.cluster-name
  role_arn = aws_iam_role.my_cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.my_cluster.id]
    subnet_ids         = aws_subnet.demo[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.my_cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.my_cluster-AmazonEKSServicePolicy,
  ]
}

resource "aws_iam_role" "demo-node" {
  name = "terraform-eks-demo-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.demo-node.name
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.demo-node.name
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.demo-node.name
}

resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "demo"
  node_role_arn   = aws_iam_role.demo-node.arn
  subnet_ids      = aws_subnet.demo[*].id

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.demo-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.demo-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}