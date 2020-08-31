This repository is for my tasks given in my  HybridMulticloud summer training from Linux world under the mentorship of Mr
Vimal Daga.
<br>
The Readme is the blog which is my self reflection that I learnt during the internship. 
This is also for my future references. 
Prior knowledege of the Terraform will be the basic requirement for the above task to be completed. 


<br>Through out all the tasks  We will be using Terraform.
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
    <li>Terraform setup in CLI</li>
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
<br>
The above steps will be common to the all the tasks so as to initialise the Terraform to work 