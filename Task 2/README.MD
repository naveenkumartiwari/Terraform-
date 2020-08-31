This repository is for my tasks given in my  HybridMulticloud summer training from Linux world under the mentorship of Mr
Vimal Daga.
<br>
In the second  task everything will do everyhting we did in the task 1 but with a slight difference,Instead of the EBS volume that is a Block storage we will use a EFS storage.<br>

AWS Elastic File System (EFS) is one of three main storage services offered by Amazon. It is a scalable, cloud-based file system for Linux-based applications and workloads that can be used in combination with AWS cloud services.EFS provides a shared stoarage for all the instances at once. 



We will launch Ec2 instance , create a EFS volume and launch this using cloudfront.
<br>We will be using Terraform.
Terraform enables us to create a complete infrastructure as a code.
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
first Lets create a EC2 instance.This will require a ami id . you can choose any ami you want with any configuration.
Dont Forget to add the commands  in the provisioner to run these as soon as the instance is created. 




```
resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  availability_zone = "ap-south-1b"
  instance_type = "t2.micro"
  key_name = "key"
  security_groups = [ "launch-wizard-1" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Naveen/Downloads/key.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec"{
     inline = [
              "sudo yum install httpd git -y" ,
              "sudo systemctl restart httpd",
              "sudo systemctl enable httpd",
 
        ]
    }

}  
```

Now we have to create a VPc in which we will launch our instance. VPC is Virtual Private Cloud which gives us separate environments for our projects. 

```
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true" 
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    
}
```


Now we have to create subnets inside the vpc we just created. subnets give us ability to isolate the diffrent resources within the same projects 
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
Each instance requires a security group which allows the traffic the kind you want.Here we will create a security group that will allow any kind of incoming or outgoing traffic. 

```
resource "aws_security_group" "my_security_group" {
  name        = "my_security_group"
  vpc_id      = aws_vpc.vpc.id

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

Our instance is ready but we have to still add the EFS storage to this , so create a EFS storage . 

```
resource "aws_efs_file_system" "efs" {
   creation_token = "efs"
   performance_mode = "generalPurpose"
   throughput_mode = "bursting"
   encrypted = "true"
 tags = {
     Name = "efs"
   }
 }
```
Now you have to give a target to which you want this EFS tsorage to attached with. So we will attach this to instance we created above.Give the subnet id and the security group. 



```
 resource "aws_efs_mount_target" "efs-mount" {
   file_system_id  = "${aws_efs_file_system.efs.id}"
   subnet_id = "${aws_subnet.subnet-1.id}"
   security_groups = ["${aws_security_group.my_security_group.id}"]
 }

```





Just Like EBS we have to also mount this EFS to the directory we want and select the path  to which we want this EFS to be mounted upon. Here we are again mounting this on the httpd path so our saved webpages can also be saved in the EFS. 


```
resource "null_resource" "dir_mount"  {

depends_on = [
    aws_volume_attachment.ebs_attach,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Naveen/Downloads/key.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - root"
                
       "sudo install -y amazon-efs-utils"
        "mount -t efs ${efs_id}:/ /var/www/html "

        "sudo git clone https://github.com/vimallinuxworld13/multicloud.git /var/www/html/"
    ]
  }
}
```




Now  Lets create a S3 Bucket for temporary storage.And doesnt need to be mounted to any single instance.
We will be using this S3 bucket for storing our data and use it further in the cloudfront. For now will make it public accesseble so that anyone can view its object and also enable the versioning.Make sure You give the bucket a globally unique name.


```
resource "aws_s3_bucket" "bucket" {
  bucket = "my-unique-terraform-bucket"
  acl = "public-read"
  versioning {
    enabled = true
  }

  tags = {
    Name = "my-terraform-bucket"
  }
}  
```
Now create a s3 object which will be stored in the bucket.Give the bucket name you want the object to be created of. 

```

 resource "aws_s3_bucket_object" "object" {
  bucket = "my-unique-terraform-bucket"
  key    = "download.png"
  source = "download.png"
  
  acl = "public-read"
  depends_on = [
       aws_s3_bucket.bucket

   ]
}
```
Now the most Important part , creating the Cloudfront.Cloudfront is CDN i.e. a content delievry system for globally distributed network. 
It retrieves data from Amazon S3 bucket and distributes it to multiple datacenter locations. It delivers the data through a network of data centers called edge locations. The nearest edge location is routed when the user requests for data, resulting in lowest latency, low network traffic, fast access to data, etc.

```
resource "aws_cloudfront_distribution" "Cloudfront" {
    origin {
         domain_name = "${aws_s3_bucket.bucket.bucket_regional_domain_name}"
         origin_id   = "${aws_s3_bucket.bucket.id}"

        custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
        }
    }
       
    enabled = true

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "${aws_s3_bucket.bucket.id}"

        
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
    
    restrictions {
        geo_restriction {
            
            restriction_type = "none"
        }
    }

    
    viewer_certificate {
        cloudfront_default_certificate = true
    }
    depends_on = [
    aws_s3_bucket.bucket
  ]
 }
```
<br>


And all done .All now you need to do is create this code and now apply this terraform code.


<br>
Now just Run the following .
<br>


```
terraform apply eks.tf
