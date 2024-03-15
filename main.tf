resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = "true"
}
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = "true"
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id

}

# resource "aws_internet_gateway_attachment" "example" {
#   internet_gateway_id = aws_internet_gateway.gw.id
#   vpc_id              = aws_vpc.myvpc.id
# }

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt.id
}


resource "aws_s3_bucket" "saibucket" {
  bucket = "bucketsai258"

}


# create security group

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    self        = true
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#Create EC2 Instances

resource "aws_instance" "EC2" {
  ami           = "ami-013168dc3850ef002"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.sub1.id
  vpc_security_group_ids = [aws_security_group.sg.id]
   user_data = base64encode(file("userdata.sh"))
  # user_data = <<-EOF
  #             #!/bin/bash
  #             echo "Hello Sai Reddy, This is Server-1" > /tmp/hello.txt
  #             EOF
  tags = {
    Name = "Ubuntu-1"
  }
}
resource "aws_instance" "EC21" {
  ami           = "ami-013168dc3850ef002"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.sub2.id
  vpc_security_group_ids = [aws_security_group.sg.id]
   user_data = base64encode(file("userdata1.sh"))
# user_data = <<-EOF
              #!/bin/bash
              # echo "Hello Revanth Reddy, This is Server-2" > /tmp/hello.txt
              # EOF



  tags = {
    Name = "Ubuntu-2"
  }
}


# Create target group

resource "aws_lb_target_group" "alb" {
  name     = "my-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.alb.arn
  target_id        = aws_instance.EC2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "test1" {
  target_group_arn = aws_lb_target_group.alb.arn
  target_id        = aws_instance.EC21.id
  port             = 80
}

# Create LB
resource "aws_lb" "mylb" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]

}


resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}