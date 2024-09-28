# Section 9 - Deploying with Kubernetes

![alt text](imgs/kubernetes.png)

- Setting up a Kubernetes cluster (EKS) with Terraform
- Create deployment- and service-files
- Create secrets
- Using secrets in the manifest file

## Creating EKS cluster with Terraform

The terraform code that is required for a EKS cluster can be found [here](../terraform_code/eks/).
The main components here are:
- IAM roles
- IAM policies
- EKS cluster
- Node group

In the next step a security group for the EKS cluster is created and can be found [here](../terraform_code/sg_eks/)

In the last step, the terraform [file](../terraform_code/V3-EC2_for_each.tf), that was used to set up everything in previous sections, is updated to use (`eks` and `sg_eks`) as terraform-modules.

```tf
# Security group of EKS cluster
module "sgs" {
  source = "../sg_eks"
  vpc_id = aws_vpc.dpp-vpc.id
}

# EKS cluster
module "eks" {
  source = "../eks"
  vpc_id = aws_vpc.dpp-vpc.id
  subnet_ids = [aws_subnet.dpp-public-subnet-01.id, aws_subnet.dpp-public-subnet-02.id]
  sg_ids = module.sgs.security_group_public
}
```

The file [V3-EC2_for_each.tf](../terraform_code/V3-EC2_for_each.tf) and all auxilary terraform files are moved to folder `vpc` (which has to be created).

## Execute Terraform manifest file to setup the EKS cluster