resource "aws_vpc" "icoach_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "icoach-vpc"
  }
}

resource "aws_subnet" "public_web_subnet_a" {
  vpc_id                  = aws_vpc.icoach_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "icoach-public-web-subnet-a"
  }

}

resource "aws_subnet" "public_web_subnet_b" {
  vpc_id                  = aws_vpc.icoach_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "icoach-public-web-subnet-b"
  }

}

resource "aws_subnet" "private_app_subnet_a" {
  vpc_id            = aws_vpc.icoach_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "icoach-private-app-subnet-a"
  }

}

resource "aws_subnet" "private_app_subnet_b" {
  vpc_id            = aws_vpc.icoach_vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "icoach-private-app-subnet-b"
  }
}

resource "aws_subnet" "data_subnet_a" {
  vpc_id            = aws_vpc.icoach_vpc.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "icoach-data-subnet-a"
  }

}
resource "aws_subnet" "data_subnet_b" {
  vpc_id            = aws_vpc.icoach_vpc.id
  cidr_block        = "10.0.31.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "icoach-data-subnet-b"
  }

}
resource "aws_internet_gateway" "icoach_igw" {
  vpc_id = aws_vpc.icoach_vpc.id
  tags = {
    Name = "icoach-igw"
  }

}

resource "aws_eip" "icoach_nat_eip_a" {
  domain = "vpc"
  tags = {
    Name = "icoach-nat-eip_a"
  }

}

resource "aws_nat_gateway" "icoach_nat_a" {
  allocation_id = aws_eip.icoach_nat_eip_a.id
  subnet_id     = aws_subnet.public_web_subnet_a.id
  tags = {
    Name = "icoach-nat_a"
  }

}

resource "aws_eip" "icoach_nat_eip_b" {
  domain = "vpc"
  tags = {
    Name = "icoach-nat-eip_b"
  }

}

resource "aws_nat_gateway" "icoach_nat_b" {
  allocation_id = aws_eip.icoach_nat_eip_b.id
  subnet_id     = aws_subnet.public_web_subnet_b.id
  tags = {
    Name = "icoach-nat_b"
  }

}








resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.icoach_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.icoach_igw.id
  }
  tags = {
    Name = "icoach-public-rt"
  }
}


resource "aws_route_table" "private_app_rt_a" {
  vpc_id = aws_vpc.icoach_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.icoach_nat_a.id
  }

  tags = {
    Name = "icoach-private-app-rt_a"
  }
}


resource "aws_route_table" "private_app_rt_b" {
  vpc_id = aws_vpc.icoach_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.icoach_nat_b.id
  }

  tags = {
    Name = "icoach-private-app-rt_b"
  }
}






resource "aws_route_table" "data_rt" {
  vpc_id = aws_vpc.icoach_vpc.id

  tags = {
    Name = "icoach-data-rt"

  }

}


resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_web_subnet_a.id
  route_table_id = aws_route_table.public_rt.id

}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_web_subnet_b.id
  route_table_id = aws_route_table.public_rt.id

}

resource "aws_route_table_association" "private_app_a_assoc" {
  subnet_id      = aws_subnet.private_app_subnet_a.id
  route_table_id = aws_route_table.private_app_rt_a.id

}

resource "aws_route_table_association" "private_app_b_assoc" {
  subnet_id      = aws_subnet.private_app_subnet_b.id
  route_table_id = aws_route_table.private_app_rt_b.id
}

resource "aws_route_table_association" "data_a_assoc" {
  subnet_id      = aws_subnet.data_subnet_a.id
  route_table_id = aws_route_table.data_rt.id

}

resource "aws_route_table_association" "data_b_assoc" {
  subnet_id      = aws_subnet.data_subnet_b.id
  route_table_id = aws_route_table.data_rt.id
}