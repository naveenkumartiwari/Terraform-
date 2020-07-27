# Terraform

This repository is for my task given in HybridMulticloud summer training from Linux world under the mentorship of<h6>Vimal Daga </h6>
<br>
In this task We will create a EKS cluster using 
Terraform.This will enable us to create and destroy the cluster just in one click. 
<h2>EKS</h2>
Amazon EKS (Elastic Container Service for Kubernetes) is a managed Kubernetes service that allows you to run Kubernetes on AWS without the hassle of managing the Kubernetes control plane.<br>

The Kubernetes control plane plays a crucial role in a Kubernetes deployment as it is responsible for how Kubernetes communicates with your cluster — starting and stopping new containers, scheduling containers, performing health checks, and many more management tasks.<br>

The big benefit of EKS, and other similar hosted Kubernetes services, is taking away the operational burden involved in running this control plane. You deploy cluster worker nodes using defined AMIs and with the help of CloudFormation, and EKS will provision, scale and manage the Kubernetes control plane for you to ensure high availability, security and scalability.<br>
<br>
We will use Terraform to create the EKS Cluster in the aws.Terraform enables us to create a complete infrastructure as a code.
This enables us to create or destroy the whole infrastructure just in one click.
<br>

<h2>Requirements</h2>
<br>
Make sure you have the following  configured 
<br>
<ul>
    <li>AWS CLI</li>
    <li>AWS cli configure with the account with IAM role permission</li>
    <li>IAM authenticator</li>
    <li>kubectl</li>
    <li>eksctl</li>
</ul>

<br>
Create a folder for your workspace for storing the all of the terraform code.<br>
Create a file for the provider with ".tf" extension  with the following code and save it.

```
provider "aws" {
    region = "ap-south-1"
    profile = "default"
}
```



<br>
Run the following in the CLI
```
terraform init 
```

Now lets add the resources in the file 

First create a VPC in which we will launch our Cluster.

```
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true" 
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    
}
```
<br>
Create the Subnets in the VPC.In this subnets the nodes of our cluster will be launched.

```
resource "aws_subnet" "subnet-1" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" 
    availability_zone = "ap-south-1a"
    tags {
        Name = "subnet-1"
    }
}
```
<br>
Now create a internet gateway that will allow the VPC to have the outside connectivity 

```
resource "aws_internet_gateway" "gateway" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "gateway"
    }
}
```
<br>
Create the route table for the internet gateway which will be all of the internet.

```
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
```
<br>

Associate the Route table to the Internet Gateway.
<br>

```
resource "aws_route_table_association" "route_table_association "{
    subnet_id = "${aws_subnet.subnet-1.id}"
    route_table_id = "${aws_route_table.route_table.id}"
}

```
<br>
Create the IAM role for your cluster

```
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
```
<br>
Attach these role policies to the IAM role
<br>
```
resource "aws_iam_role_policy_attachment" "my_cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.my_cluster.name
}

resource "aws_iam_role_policy_attachment" "my_cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.my_cluster.name
}

```
<br>
Create the security Group for the cluster and give the allowed ip ranges 
<br>
```
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
```

<br>
Allow the network protocols for the security group
<br>
```
resource "aws_security_group_rule" "my_cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.my_cluster.id
  to_port           = 443
  type              = "ingress"
}
```


Create the EKS Cluster with the created VPC and subnets.

```
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
```
Create the demo node

```
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


```

Attach these policies to the Nodes

```
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

```

Create the Node Group

```
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

```


And all done .All now you need to do is create this code and now apply this terraform code.






<br>
Now just Run the following .
<br>


```
terraform apply eks.tf
```
