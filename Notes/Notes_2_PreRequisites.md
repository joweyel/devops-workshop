# Section 2 - Pre-requisites

## Required Tools
- VScode (code creation)
- Git (version control)
- awscli (interation with aws)
- Terraform (for resource provisioning)
- ssh-client (gui or cli)

## Install VSCode
- Obtain VSCode from here: https://code.visualstudio.com/download

## Install Git
- **On Windows**:
  - Obtain Gitbash from here: https://git-scm.com/downloads
- **On Linux (Ubuntu)**:
  ```bash
  sudo apt-get install git
  ```


## Install Terraform
- Install Terraform according to the instructions here: https://developer.hashicorp.com/terraform/install

## Install AWSCLI(v2)
1. Install AWSCLI(v2)
   - Link: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
2. Create IAM User with admin-access
   - Name: terraform
   - Attach: `AdministratorAccess` to iam user (premissions can be reduced later)
   - Create access keys for CLI access
   - Tag: terraform credentials
   - Download the credentials
3. Run `aws coinfigure --profile <iam-user-name>`
   - configuring the IAM user in awscli by setting access keys and region
   - Check if it worked by running `aws s3 ls` while having an S3 bucket present