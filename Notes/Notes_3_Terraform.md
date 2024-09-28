# Section 3 - Terraform

## Introduction
- Provisioning EC2 instances and other resources

## Source code reference
- tweet-trend: https://github.com/ravdy/tweet-trend
- devops-workshops: https://github.com/ravdy/devops-workshop

## Github repo 
- Create your own github repo `devops-workshop` and clone it
- *OR* fork the original [devops-workshop](https://github.com/ravdy/devops-workshop) by ravdy and use the fully present code

## Writing a Terraform file

- Always requires "provider block" and "resource block"
- **Provider block** specifies provider, project name and region
  ```sh
  provider "aws" {
    project = "acme-app"
    region = "us-east-1"
  }
  ```
- **Resource block**: provides informationen about instances that have to be created
  ```sh 
  resource "aws_instance" "web" {
    ami           = "ami-a1b2c3d4"
    instance_type = "t2.micro"
    keypair       = "demo_key"
  }
  ```
   Possible parameters for provisioning a EC2 instance are:
    - Instance name
    - Operating system (AMI)
    - instance Type 
    - Keypair
    - VPC
    - Storage

## Terraform Commands
```bash
terraform init      # Prepare working directoryfor other commands
terraform validate  # Check if configuration is valid
terraform plan      # Show changes required by the current project configuration
terraform apply     # Create of update infrastructure 
terraform delete    # Destroy previously created infrastructure
```

### Example
- Create terraform file `main.tf`
  ```bash
  provider "aws" {
    region = "us-east-1"

  }

  resource "aws_instance" "demo-server" {
    ami           = "ami-0ebfd941bbafe70c6"
    instance_type = "t2.micro"
    key_name      = "ddp"
  }
  ```
- Run the following commands:
  ```bash
  terraform init        # Initialize folder for aws
  terraform validate    # check if main.tf is valid tf-file
  terraform plan        # Give a rough plan of the ressources
  terraform apply       # Apply the ressources
  ```


## Create security group with terraform
Add this to `main.tf`

```tf
resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH Access"
  
  ingress {
    description      = "Shh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-prot"

  }
}
```

## Create VPC and EC2 with Terraform
1. Create VPC
2. Create a Subnet
3. Create Internet Gateway
4. Create Route Table
5. Route Table Association

### 1. Create VPC
```bash
resource "aws_vpc" "dpw-vpc" {
    cidr_block = "10.1.0.0/16"
    tags = {
        Name = "dpw-vpc"
    }
}
```

### 2. Create Subnet
- Creating subnet under vpc
  
```bash
resource "aws_subnet" "dpw-public_subnet_01" {
    vpc_id = aws_vpc.dpw-vpc.id  # where the subnet is created (dynamic id)
    cidr_block  "10.1.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
    tags = {
        Name = "dpw-public_subnet_01"
    }
}
```

### 3. Create Internet Gateway
```bash
resource "aws_internet_gateway" "dpw-igw" {
    vpc_id = aws_vpc.dpw-vpc.id
    tags = {
        Name = "dpw-igw
    }
}
```

### 4. Create Route Table
```bash
resource "aws_route_table" "dpw-public-rt" {
    vpc_id = aws_vpc.dpw-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.dpw-igw.id
    }
    tags = {
        Name = "dpw-public-rt"
    }
}
```


### 5. Route Table association
```bash
resource "aws_route_table_association" "dpw-rta-public-subnet-1" {
    subnet_id = aws_subnet.dpw-public_subnet_01.id
    route_table_id = aws_route_table.dpw-public-rt.id
}
```


The full script:
```bash
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "demo-server" {
  ami           = "ami-022e1a32d3f742bd8"
  instance_type = "t2.micro"
  key_name      = "ddp"
  // security_groups = [ "demo-sg" ]
  vpc_security_group_ids = [aws_security_group.demo-sg.id]
  subnet_id              = aws_subnet.dpp-public-subnet-01.id
}

resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH Access"
  vpc_id      = aws_vpc.dpp-vpc.id

  ingress {
    description = "Shh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-prot"

  }
}

resource "aws_vpc" "dpp-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "dpp-vpc"
  }
}

resource "aws_subnet" "dpp-public-subnet-01" {
  vpc_id                  = aws_vpc.dpp-vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "dpp-public-subnet-01"
  }
}

resource "aws_subnet" "dpp-public-subnet-02" {
  vpc_id                  = aws_vpc.dpp-vpc.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1b"
  tags = {
    Name = "dpp-public-subnet-02"
  }
}

resource "aws_internet_gateway" "dpp-igw" {
  vpc_id = aws_vpc.dpp-vpc.id
  tags = {
    Name = "dpp-igw"
  }
}

resource "aws_route_table" "dpp-public-rt" {
  vpc_id = aws_vpc.dpp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dpp-igw.id
  }
}

resource "aws_route_table_association" "dpp-rta-public-subnet-01" {
  subnet_id      = aws_subnet.dpp-public-subnet-01.id
  route_table_id = aws_route_table.dpp-public-rt.id
}
```

## Create DevOps instances using *for_each* in Terraform

### `for_each` in Terraform
- For creating multiple EC2 instances in terraform

```bash
for_each = toset(["master", "slave"])
    tags = {
        Name = "${each.key}"
    }
```