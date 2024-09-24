provider "aws" {
  region = "us-east-1"

}

resource "aws_instance" "demo-server" {
  ami           = "ami-0ebfd941bbafe70c6"
  instance_type = "t2.micro"
  key_name      = "ddp"
}