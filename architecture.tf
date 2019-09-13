provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "test" {

  cidr_block = "10.0.0.0/16"
  tags = {
    name = "My_first_test_VPC"
  }
}

#Here we are creating two Elastic IPs for our NATs

resource "aws_eip" "eip1" {
  vpc = true
  tags = {
    Name = "Elastic IP for first NAT"
  }
}

resource "aws_eip" "eip2" {
  vpc = true
  tags = {
    Name = "Elastic IP for second NAT"
  }
}

# Here we are creating an Internet Gateway which will be attached to the public subnets
resource "aws_internet_gateway" "intergw" {
  vpc_id = "${aws_vpc.test.id}"
}

#Here we are creating a NAT Gateway for our private subnets

resource "aws_nat_gateway" "natgw1" {
  allocation_id = "${aws_eip.eip1.id}"
  subnet_id     = "${aws_subnet.subnet_pub1.id}"

  tags = {
    Name = "The NAT Gateway in public1"
  }
}

resource "aws_nat_gateway" "natgw2" {
  allocation_id = "${aws_eip.eip2.id}"
  subnet_id     = "${aws_subnet.subnet_pub2.id}"
  tags = {
    Name = "The NAT Gateway in public2"
  }
}

# provisioner "file" = {
#       content = "${data.template_file.net_id.rendered}"
#       destination = "/Users/constantine/Documents/Terraform_projects/beginning.tf"
#     }


##########################################




#Now we will associate the subnet with the route table_mappings
resource "aws_route_table_association" "subnet_pub1" {
  subnet_id      = "${aws_subnet.subnet_pub1.id}"
  route_table_id = "${aws_route_table.route_public.id}"

}

resource "aws_route_table_association" "subnet_pub2" {
  subnet_id      = "${aws_subnet.subnet_pub2.id}"
  route_table_id = "${aws_route_table.route_public.id}"

}


resource "aws_route_table_association" "subnet_db1" {
  subnet_id      = "${aws_subnet.subnet_db1.id}"
  route_table_id = "${aws_route_table.route_database.id}"

}

resource "aws_route_table_association" "subnet_db2" {
  subnet_id      = "${aws_subnet.subnet_db2.id}"
  route_table_id = "${aws_route_table.route_database.id}"

}
##########################################


# Here we will create a route table and route itslef

resource "aws_route_table" "route_public" {
  vpc_id = "${aws_vpc.test.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.intergw.id}"
  }
  tags = {
    Name = "public_route"
  }
}

resource "aws_route_table" "route_database" {
  vpc_id = "${aws_vpc.test.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.natgw1.id}"
  }
  tags = {
    Name = "database_route"
  }
}
##########################################
resource "aws_subnet" "subnet_pub1" {

  vpc_id                  = "${aws_vpc.test.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = "true"
  tags = {
    name = "first_public_subnet"
  }
}

resource "aws_subnet" "subnet_pub2" {

  vpc_id                  = "${aws_vpc.test.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = "true"
  tags = {
    name = "second_public_subnet"
  }
}


resource "aws_subnet" "subnet_prv1" {

  vpc_id            = "${aws_vpc.test.id}"
  cidr_block        = "10.0.0.1/24"
  availability_zone = "eu-central-1a"
  tags = {
    name = "first_private_subnet"
  }
}

resource "aws_subnet" "subnet_prv2" {

  vpc_id            = "${aws_vpc.test.id}"
  cidr_block        = "10.0.0.2/24"
  availability_zone = "eu-central-1b"
  tags = {
    name = "second_private_subnet"
  }
}


resource "aws_subnet" "subnet_db1" {

  vpc_id            = "${aws_vpc.test.id}"
  cidr_block        = "10.1.0.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    name = "first_database_subnet"
  }
}

resource "aws_subnet" "subnet_db2" {

  vpc_id            = "${aws_vpc.test.id}"
  cidr_block        = "10.2.0.0/24"
  availability_zone = "eu-central-1b"
  tags = {
    name = "second_database_subnet"
  }
}
##########################################
#Creation security group for azurerm_lb_probe
resource "aws_security_group" "for_alb" {
  name        = "HTTP_HTTPS_SSH_SG"
  description = "Allow HTTP HTTPs and SSH traffic"
  vpc_id      = "${aws_vpc.test.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 80
    protocol    = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "SSH"
    cidr_blocks = ["0.0.0.0/0"] #it's better to change that for production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
##########################################
#Creating of the Application Load Balancer

resource "aws_lb" "app_elb" {
  name               = "mybalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.for_alb.id}"]
  subnets            = ["${aws_subnet.subnet_pub1.id}", "${aws_subnet.subnet_pub2.id}"]

  enable_deletion_protection = false

  tags = {
    Name = "Internet-facing ALB for web servers"
  }
}
##########################################

#creating Auto_scaling group and attaching ALB there

resource "aws_autoscaling_group" "myauto" {
  name                      = "autoscaling-for-web"
  max_size                  = 6
  min_size                  = 2
  health_check_grace_period = 400
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.golden_lc.name}"
  vpc_zone_identifier       = ["${aws_subnet.subnet_pub1.id}", "${aws_subnet.subnet_pub2.id}"]
  target_group_arns         = ["${aws_lb.app_elb.arn}"]


  tag {
    key                 = "name"
    value               = "launched_with_golden_ami"
    propagate_at_launch = true #will be attached to a created instance
  }

  timeouts {
    delete = "10m"
  }
}



##########################################
#Getting the list of snapshots and copying a particular one to the 2nd(recovered) region
data "aws_ebs_snapshot_ids" "ebs_volumes" {
  #returns IDs of snapshots sorted by creation time in descending order.
  filter {
    name   = "tag:Name"
    values = ["snap-recovery"] # all our backups has this tag
  }
}

output "ebs_snapshot_ids" {
  value = ["${data.aws_ebs_snapshot_ids.ebs_volumes.ids}"]
}

resource "aws_ebs_snapshot_copy" "needed_copy" {
  source_snapshot_id = "${data.aws_ebs_snapshot_ids.ebs_volumes.ids.0}"
  source_region      = "eu-west-1"

  tags = {
    Name = "my_copy_to_restore"
  }
}
##########################################
#Creating AMI (for our launch configuration) from the latest snapshot ( as a root volume)

resource "aws_ami" "ami_for_recovery" {
  name = "recover-ami-ran-pam"

  ebs_block_device {
    device_name = "/dev/xvda"
    snapshot_id = "${aws_ebs_snapshot_copy.needed_copy.id}"
  }
}
##########################################
#creating launch configuration for our autoscaling_groups

resource "aws_launch_configuration" "golden_lc" {
  name_prefix   = "terraform-lc-"
  image_id      = "${aws_ami.ami_for_recovery.id}"
  instance_type = "t2.micro"
  user_data     = file("shell.sh")

  lifecycle {
    create_before_destroy = true
  }
}
