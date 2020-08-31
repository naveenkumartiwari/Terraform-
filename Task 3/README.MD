This repository is for my tasks given in my  HybridMulticloud summer training from Linux world under the mentorship of Mr
Vimal Daga.
<br>
<br>We will be using Terraform.
Terraform enables us to create a complete infrastructure as a code.
This enables us to create or destroy the whole infrastructure just in one click.
<br>
This is the task 3 in which we will be doing following things 
<br>
-create a VPC. <br>

-In that VPC we have to create 2 subnets:<br>
    a)  public  subnet [ Accessible for Public World! ] <br>
    b)  private subnet [ Restricted for Public World! ] <br>

-Create a public facing internet gateway for connect our VPC/Network to the internet world and attach this gateway to our VPC.<br>

-Create  a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.<br>

-Launch an ec2 instance which has Wordpress setup already having the security group allowing  port 80 so that our client can connect to our wordpress site.
Also attach the key to instance for further login into it.<br>

-Launch an ec2 instance which has MYSQL setup already with security group allowing  port 3306 in private subnet so that our wordpress vm can connect with the same.
Also attach the key with the same.<br>

<h2>Requirements</h2>
<br>
Make sure you have the following  configured 
<br>
<ul>
    <li>AWS CLI</li>
    <li>AWS cli configure with the account with IAM role permission</li>
    <li>IAM authenticator</li>
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
<br> 

First  we have to create a VPc in which we will launch our instance. VPC is Virtual Private Cloud which gives us separate environments for our projects. 

```
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true" 
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    
}
```

We will need a internet gateway to connect our vpc to the public network so that the oustide world and our own instance can connect to each other.IT  is a network "node" that connects two different networks that use different protocols (rules) for communicating.  

```
resource "aws_internet_gateway" "gateway" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "gateway"
    }
}
```
Now come to the subnet, as you know we will require a subnet in which we will launch the instance.Here We have to launch a worpress with a mysql instance hence we will create two subnets where in the first subnet will be public subnet which is connected to the internet , bu the second one will be private subnet where only allowed connections can connect to the instances launched in this subnet. This is because MYSQL is a database which should be kept confidential and shouldnt be exposed to the outside world hence only the instances in the public subnet can connect to it. 
So lets create the subnets 

<br> 
first lets create the public subnet 

```
resource "aws_subnet" "subnet-public" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = "true" 
    availability_zone = "ap-south-1a"
    tags {
        Name = "subnet-public"
    }
}

```
Now we have to create a route table. <br>
A routing table is a set of rules, often viewed in table format, that is used to determine where data packets traveling over an Internet Protocol (IP) network will be directed. All IP-enabled devices, including routers and switches, use routing tables.4
Create a route table for the public subnet which will have the rule to route any traffic. 
It will be associated to the internet gateway we created above 


```
resource "aws_route_table" "route_table_public" {
    vpc_id = "${aws_vpc.main-vpc.id}"
    
    route {
        
        cidr_block = "0.0.0.0/0" 
        
        gateway_id = "${aws_internet_gateway.gateway.id}" 
    }
    
    tags {
        Name = "route_table_public" 
    }
}
```
Now we have to associate the above created route table to the public subnet 


```
resource "aws_route_table_association" "route_table_association_public"{
    subnet_id = "${aws_subnet.subnet-public.id}"
    route_table_id = "${aws_route_table.route_table_public.id}"
}
```

Now You have a complete setup for the public subnet.Any instance launched in this usbnet will have a internet connectivity
Now Do the above same steps for private subnet i.e create a private subnet , 
create the route table and associate.



```
resource "aws_subnet" "subnet-private" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
    tags {
        Name = "subnet-private"
    }
}

resource "aws_route_table" "route_table_private" {
    vpc_id = "${aws_vpc.main-vpc.id}"
    
    route {
        
        cidr_block = "0.0.0.0/0" 
        
        gateway_id = "${aws_internet_gateway.gateway.id}" 
    }
    
    tags {
        Name = "route_table_private" 
    }
}


resource "aws_route_table_association" "route_table_association_public"{
    subnet_id = "${aws_subnet.subnet-private.id}"
    route_table_id = "${aws_route_table.route_table_private.id}"
}
```

Now we have to create the security groups for our instances.It will act like a firewall that is only allowed traffic can come or go out. 
<br>
First lets create the security groups for our wordpress instance. 
for this instance allow ssh and http traffic and the port for mysql , because we also want the mysql instance to be fully connected to the wordpress instance.

```
resource "aws_security_group" "wordpress_sg" {
    name = "wordpress_sg"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress { 
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = "10.0.1.0/24"
    }

    vpc_id = "${aws_vpc.vpc.id}"


}
```

Now create the security group for the mysql instance. 
This wont allow public internet traffic.It will allow only the network traffic from the wordpress instance. 

```
resource "aws_security_group" "database_sg" {
    name = "vpc_db"

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = ["${aws_security_group.wordpress_sg.id}"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = "10.0.0.0/16"
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = "10.0.0.0/16"
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.vpc.id}"

    
}
```
NOw everything is set for the connectivity and setup is ready to have the instances launched <br>
so Launch a worpress Instance in the public subnet 


```
resource "aws_instance" "wordpress" {
  ami           = "ami-0669a96e355eac82f"
  availability_zone = "ap-south-1b"
  instance_type = "t2.micro"
  key_name = "key"
  vpc_security_group_ids = ["${aws_security_group.wordpress_sg.id}"]
  subnet_id = "${aws_subnet.subnet-public.id}"
  associate_public_ip_address = true
  
  
}
```

Similarly launch a mysql image in the private subnet .
Note that  you can use any ami image or database type you want.


```
resource "aws_instance" "database" {
    ami = "ami-00cb1de6eb870cec2"
    availability_zone = "sa-east-1a"
    instance_type = "t2.micro"
    key_name = "key"
    vpc_security_group_ids = ["${aws_security_group.database_sg.id}"]
    subnet_id = "${aws_subnet.subnet-private.id}"
    
}
```


<br>


And all done .All now you need to do is create this code and now apply this terraform code.


<br>
Now just Run the following .
<br>


```
terraform apply eks.tf
```