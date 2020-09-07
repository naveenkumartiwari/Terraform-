This repository is for my tasks given in my  HybridMulticloud summer training from Linux world under the mentorship of Mr
Vimal Daga.
<br>
<br>We will be using Terraform.
Terraform enables us to create a complete infrastructure as a code.
This enables us to create or destroy the whole infrastructure just in one click.
<br>

This is Task 6 in which we will do the following tasks , 

<ul>
  
 <li> Write an Infrastructure as code using terraform, which automatically deploy the Wordpress application</li>

<li>On AWS, use RDS service for the relational database for Wordpress application.</li>

<li>Deploy the Wordpress as a container  on top of Minikube </li>

<li>The Wordpress application should be accessible from the public world if deployed on AWS or through workstation if deployed on Minikube.</li>

</ul>

<h2>Requirements</h2>
<br>
Make sure you have the following  configured 
<br>
<ul>
    <li>AWS CLI</li>
    <li>AWS cli configure with the account with IAM role permission</li>
    <li>IAM authenticator</li>
    <li>Minikube configured</li>
    <li>Kubenetes setup on CLI</li>
</ul>
<h2>What is Kubernetes </h2><br>
Kubernetes is a popular open source platform for container orchestration — that is, for the management of applications built out of multiple, largely self-contained runtimes called containers. Containers have become increasingly popular since the Docker containerization project, but large, distributed containerized applications can become increasingly difficult to coordinate. By making containerized applications dramatically easier to manage at scale, Kubernetes has become a key part of the container revolution.<br>

<h2>What is Minikube</h2> <br>
Minikube is a tool that makes it easy to run Kubernetes locally. Minikube runs a single-node Kubernetes cluster inside a Virtual Machine (VM) on your laptop for users looking to try out Kubernetes or develop with it day-to-day.<br>
Here we will be launching the wordpress Application On top of the Minikube.You can launch it on any other Kubernetes cluster on cloud 
like EKS or , GKE . 

<br>
First Lets launch a worpress aplication on our minikube 
<br>
Create a file for the provider with ".tf" extension  with the following code and save it.
<br>

```
provider "kubernetes" {
  config_context_cluster   = "minikube"
}
```


<br>

Run the following in the CLI

```
terraform init
```

Now lets add the resources in the file
<br>

First Lets launch the minikube from the CLI , I have added the null resource command to locally execute the command for launching the minikube or you can do it manually on CLI . 


```
resource "null_resource" "minikube_launch"{

    provisioner "local_exec" {
    
    command = "minikube start" 
       
    }
}
```


Now create a deployment for the wordpress application.The following Code will create a deployement on the minikube cluster with 2 replicas of the container using the Wordpress image.Give the Appropriate labels. 



```
resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wordpress_site"
    labels = {
      env = "testing"
    }
  }


  spec {
    replicas = 2


    selector {
      match_labels = {
        env = "testing"
      }
    }


    template {
      metadata {
        labels = {
          env = "testing"
        }
      }


      spec {
        container {
          image = "wordpress"
          name  = "my_wordpress_site"
        }
      }
    }
  }
}

```
Now We have to create the Nodeport and expose our deployment to the port. A NodePort service is the most primitive way to get external traffic directly to your service. NodePort, as the name implies, opens a specific port on all the Nodes (the VMs), and any traffic that is sent to this port is forwarded to the service.You can only use ports 30000–32767. 


```
resource "kubernetes_service" "kube_Service" {
  metadata {
    name = "kubeservice"
  }
  spec {
    selector = {
      env = kubernetes_pod.wordpress.metadata.0.labels.env
    }
    port {
      node_port   = 32000 
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}
```

Output the IP of your minikube and this will give you the address where you can get to your wordpress aplicatio. 
You can also execute this locally on you CLI. 


```
resource "null_resource" "minikube_wordpress_url" {
 provisioner "local-exec" {
  command = "minikube ip"
 }

}
```
Now you need to do is create this code and now apply this terraform code.This will launch the wordpress on the minikube . and after completed , this will output the ip of your minkube cluster. 


<br>
Now just Run the following .
<br>


```
terraform apply 

```

Now Go to this Ip in your web broswer with the nodeport and you will be directed to the wordpress setup page.This page will ask you the for the database url, username and  password . 
Now we have to give it a database to connect to and we will create this database over RDS .







<br>
Now We will be Launching the RDS service on the AWS for the database for our wordpress Application.
<br>

<h2>What is RDS</h2><br>

Amazon Relational Database Service (Amazon RDS) is a managed SQL database service provided by Amazon Web Services (AWS). Amazon RDS supports an array of database engines to store and organize data and helps with database management tasks, such as migration, backup, recovery and patching.

You can use Amazon RDS to set up, manage and scale a relational database instance in the cloud. The service also automatically backs up RDS database instances, captures a daily snapshot of data and retains transaction logs to enable point-in-time recovery. RDS also automatically patches database engine software.
<br>
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
<br>

First  we have to create a VPC in which we will launch our instance. VPC is Virtual Private Cloud which gives us separate environments for our projects. 

```
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true" 
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    
}
```
Now Create a Security group for our Database so that our wordpress application on minikube  can connect to this database on AWS. 
Allow port 3306 for the mysql. 


```
resource "aws_security_group" "database_security_group" {


  name        = "database"
                  
  vpc_id      =  aws_vpc.vpc.id 


  ingress {
    
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  
}
```

Now create the Database Instance and dont forget it to make it publiclly accessible so that the worpress apllication can reach it. 
Give the security group id you just created above and set the username and password for your database psecurity. 



```
resource "aws_db_instance" "database" {
  allocated_storage = 10
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"
  name     = "my_database"
  username = "user"
  password = "password"
  port     = "3306"
  publicly_accessible = true
  iam_database_authentication_enabled = true
  vpc_security_group_ids = aws_security_group.database_security_group.id 
  
}
```


Output the URL of the Database so that you can directly paste it in the worpress application otheriwse you can go to AWS console and from the database you can copy the url after you have applied the code. 


```
output "database_url"{

    value = aws_db_instance.database.address 
}
```

And all done .All now you need to do is create this code and now apply this terraform code.


<br>
Now just Run the following .
<br>


```
terraform apply 

```

Now Pass the url of the database to the worpress application and give the username and password of the database , and your wordpress application is Ready to use. 





