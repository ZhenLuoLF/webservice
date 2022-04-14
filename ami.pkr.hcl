variable "aws_access_key_id" {
  type    = string
  default = ""
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_secret_accesss_key" {
  type    = string
  default = ""
}

variable "source_ami" {
  type    = string
  default = "ami-0c02fb55956c7d316"
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "subnet_id" {
  type    = string
  default = ""
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "autogenerated_1" {
  access_key      = "${var.aws_access_key_id}"
  ami_description = "Amazon Linux 2 AMI for CSYE 6225"
  ami_name        = "csye6225_spring2022_${local.timestamp}"
  ami_users = [
    "619083854262",
    "489783191838",
  ]
  instance_type = "t2.micro"
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    volume_size           = 20
    volume_type           = "gp2"
  }
  region       = "${var.aws_region}"
  secret_key   = "${var.aws_secret_accesss_key}"
  source_ami   = "${var.source_ami}"
  ssh_username = "${var.ssh_username}"
  subnet_id    = "${var.subnet_id}"
}

build {
  sources = ["source.amazon-ebs.autogenerated_1"]

  provisioner "file" {
    source      = "./website"
    destination = "/tmp/"
  }
  provisioner "file" {
    source      = "./requirements.txt"
    destination = "/tmp/"
  }
  provisioner "file" {
    source      = "./amazon-cloudwatch-config.json"
    destination = "/tmp/"
  }
  provisioner "shell" {
    inline = [
      "sudo yum -y update",


      "sudo yum -y install ruby",
      "sudo yum -y install wget",
      "sudo yum -y groupinstall \"Development Tools\"",
      "sudo yum -y install -y amazon-linux-extras",
      "sudo amazon-linux-extras enable python3.8",
      "sudo yum -y install python3.8",
      "sudo yum -y install python38-devel mysql-devel",
      "sudo yum -y install python38-tkinter.x86_64",
      "sudo yum -y install httpd httpd-devel",
      "python3.8 -m venv venv",
      "source ~/venv/bin/activate",



      "cd /tmp",
      "pip install -r requirements.txt",
      "sudo ~/venv/bin/mod_wsgi-express install-module",
      "sudo cp -r ./website /var/www",
      "sudo cp amazon-cloudwatch-config.json /opt",
      "cd /var/www/",
      "sudo chown -R apache:apache .",

      "cd /etc/httpd/conf ",
      "sudo sed -i '$a LoadModule wsgi_module \"/usr/lib64/httpd/modules/mod_wsgi-py38.cpython-38-x86_64-linux-gnu.so\"' httpd.conf",
      "sudo sed -i '$a WSGIPythonHome \"/home/ec2-user/venv\"' httpd.conf",
      "sudo sed -i '$a WSGIScriptAlias / /var/www/website/website/wsgi.py' httpd.conf",
      "sudo sed -i '$a WSGIPythonPath /var/www/website' httpd.conf",
      "sudo sed -i '$a WSGIPassAuthorization on' httpd.conf",
      "sudo sed -i '$a <Directory /var/www/website/website>' httpd.conf",
      "sudo sed -i '$a <Files wsgi.py>' httpd.conf",
      "sudo sed -i '$a Require all granted' httpd.conf",
      "sudo sed -i '$a </Files>' httpd.conf",
      "sudo sed -i '$a </Directory>' httpd.conf",
      "cd ~/",
      "sudo chmod 755 -R /home",
      "cd /home/ec2-user",
      "wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install",
      "chmod +x ./install",
      "sudo ./install auto",
      "sudo yum -y install amazon-cloudwatch-agent",
      "sudo service codedeploy-agent start",
    ]
  }
}