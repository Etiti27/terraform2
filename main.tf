#declared aws provider


#vpc provider
resource "aws_vpc" "instance_vpc" {
    cidr_block = var.vpc_cidr
    tags = {
      name = "Ornelta vpc"
    }
}
#first subnet
resource "aws_subnet" "first_subnet" {
  vpc_id     = aws_vpc.instance_vpc.id
  cidr_block = "10.0.0.0/25"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "first_subnet"
    description="first subnet"
  }
}
#DEVOP= DEVELOPMENT OPERATION
resource "aws_subnet" "second_subnet" {
  vpc_id     = aws_vpc.instance_vpc.id
  cidr_block = "10.0.0.128/25"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "second_subnet"
    description="second subnet"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.instance_vpc.id

  tags = {
    Name = "Ornelta vpc gateway"
  }
}



resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.instance_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

 
  tags = {
    Name = "Route table"
  }
}

resource "aws_route_table_association" "RTA1" {
  subnet_id      = aws_subnet.first_subnet.id
  route_table_id = aws_route_table.RT.id
}
resource "aws_route_table_association" "RTA2" {
  subnet_id      = aws_subnet.second_subnet.id
  route_table_id = aws_route_table.RT.id
}


resource "aws_security_group" "sg" {
  name        = "COsg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.instance_vpc.id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    protocol = "-1"
    
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 80
    to_port = 80
    protocol = "tcp"
    description = "Allow http inbound traffic and all outbound traffic"
    
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port = 22
    protocol = "tcp"
    description = "Allow SSH inbound traffic and all outbound traffic"
    
  }

  tags = {
    Name = "COsg"
  }
}
resource "aws_s3_bucket" "mybucket" {
    bucket = "orneltchris"
  
}
resource "aws_key_pair" "mykeykeypair" {
    key_name = "mykey"
    public_key = file("~/.ssh/id_rsa.pub")
  
}
# Create a new instance
resource "aws_instance" "ChrisOrnelta1" {
  ami           = var.AMI
  instance_type = lookup(var.instance_type, terraform.workspace, "t2.micro")
  subnet_id     = aws_subnet.first_subnet.id
#   security_groups = [ aws_security_group.sg ]
  vpc_security_group_ids = [ aws_security_group.sg.id ]
  user_data = base64encode(file("index.html"))


# use this if you want to execute advance web application like node app etc
 connection {
    host = self.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file("~/.ssh/id_rsa.pub")
  }
   /* 
  provisioner "file" {
    source = "index.thml"
    destination = "/home/ubuntu/index.html"
    
  }
  provisioner "remote-exec" {
    inline = [ 
        "echo 'Hello from this side' ",
        "sudo apt update -y",
        "sudo apt-get install -y",
        "cd /home/ubuntu",
        "sudo python3 app.js"
     ]
    
  } */



  
 

  tags = {
    Name = "Ornelta Instance"
  }
}
resource "aws_instance" "ChrisOrnelta2" {
  ami           = var.AMI
  instance_type = lookup(var.instance_type, terraform.workspace, "t2.micro")
  subnet_id     = aws_subnet.second_subnet.id
#   security_groups = [ aws_security_group.sg ]
  vpc_security_group_ids = [ aws_security_group.sg.id ]
  user_data = base64encode(file("index.html"))


# use this if you want to execute advance web application like node app etc
  connection {
    host = self.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file("~/.ssh/id_rsa.pub")
  }
  /* 
  provisioner "file" {
    source = "index.thml"
    destination = "/home/ubuntu/index.html"
    
  }
  provisioner "remote-exec" {
    inline = [ 
        "echo 'Hello from this side' ",
        "sudo apt update -y",
        "sudo apt-get install -y",
        "cd /home/ubuntu",
        "sudo python3 app.js"
     ]
    
  } */



  
 

  tags = {
    Name = "Ornelta Instance"
  }
}

resource "aws_lb" "load_balancer" {
  name               = "loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [aws_subnet.first_subnet.id, aws_subnet.second_subnet.id]

  enable_deletion_protection = true
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = "lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.instance_vpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "lb_tg_att1" {
  target_group_arn = aws_lb_target_group.lb_target_group.arn
  target_id        = aws_instance.ChrisOrnelta1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "lb_tg_att2" {
  target_group_arn = aws_lb_target_group.lb_target_group.arn
  target_id        = aws_instance.ChrisOrnelta2.id
  port             = 80
}
resource "aws_lb_listener" "lb_tg_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}