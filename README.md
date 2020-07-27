# Terraform

This repository is for my task given in HybridMulticloud summer training from Linux world under the mentorship of 
<h6>Vimal Daga </h6>
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
Create a file for the provider with the following code and save it.

```
provider "aws" {
    region = "ap-south-1"
    profile = "default"
}
```


Run the following in the CLI
```
terraform init 
```




























<br>
For quickly launching the cluster clone this repostory and run the following .
<br>


```terraform apply eks.tf ```
