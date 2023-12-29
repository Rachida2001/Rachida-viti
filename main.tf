provider "aws" {
  region = "us-east-1"
}

# EC2 Security Group
resource "aws_security_group" "ec2_sg" {
  vpc_id = "vpc-06a8b32229de43ca2"
  # Ingress rule allowing SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  vpc_id       = "vpc-06a8b32229de43ca2"
  name_prefix  = "wordpress-db-"

  # Ingress rule allowing connections only from EC2 Security Group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
}

# Create EC2 Instance
resource "aws_instance" "wordpress_instance" {
  ami           = "ami-079db87dc4c10ac91"
  instance_type = "t2.micro"
  key_name      = "pro_key"  # Specified key pair
  subnet_id     = "subnet-0de229aa907b603cf"  # Subnet ID
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "WordPress-Instance"
  }
}

# Create a subnet group for RDS
resource "aws_db_subnet_group" "wordpressdb_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = ["subnet-00bd5c670f7e228e0", "subnet-063b6a6f4e90b78e0"]
}

# Create RDS MySQL instance
resource "aws_db_instance" "wordpressdb" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  identifier           = var.database_name
  username             = var.database_user
  password             = var.database_password
  db_subnet_group_name = aws_db_subnet_group.wordpressdb_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "wordpress-rds"
  }
}

# Output: Public IP of the EC2 Instance
output "wordpress_public_ip" {
  value = aws_instance.wordpress_instance.public_ip
}

# Call userdata script
data "template_file" "user_data" {
  template = file("userdata.sh")
  vars = {
    db_username = var.database_user
    db_user_password = var.database_password
    db_name = var.database_name
    db_RDS = aws_db_instance.wordpressdb.endpoint
  }
}
