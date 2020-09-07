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
Kubernetes is a portable, extensible, open-source platform for managing containerized workloads and services, that facilitates both declarative configuration and automation. It has a large, rapidly growing ecosystem. Kubernetes services, support, and tools are widely available.<br>

<h2>What is Minikube</h2> <br>
Minikube is a tool that makes it easy to run Kubernetes locally. Minikube runs a single-node Kubernetes cluster inside a Virtual Machine (VM) on your laptop for users looking to try out Kubernetes or develop with it day-to-day.<br>
Here we will be launching the wordpress Application On top of the Minikube.You can launch it on any other Kubernetes cluster on cloud 
like EKS or , GKE . 
