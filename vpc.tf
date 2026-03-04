# 1. VPC 생성
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "${var.project_name}-vpc"
    }
}

# 2. 퍼블릭 서브넷 생성
resource "aws_subnet" "public_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr
    availability_zone = "${var.region}a"
    map_public_ip_on_launch = true # 퍼블릭 IP 자동 할당 옵션을 추가

    tags = {
        Name = "${var.project_name}-public-1"
    }
}

# 3. 인터넷 게이트웨이 (IGW)
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.project_name}-igw"
    }
}

# 4. 라우트 테이블
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main.id    

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "${var.project_name}-public-rt"
    }
}

# 5. 서브넷-라우트 테이블 연결
resource "aws_route_table_association" "public_1_assoc" {
    subnet_id      = aws_subnet.public_1.id
    route_table_id = aws_route_table.public_rt.id
}

# 두 번째 퍼블릭 서브넷 (가용 영역 ap-northeast-2c 사용)
resource "aws_subnet" "public_2" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.2.0/24" # 10.0.1.0과 겹치지 않게 설정
    availability_zone       = "${var.region}c"
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.project_name}-public-2"
        # EKS가 이 서브넷을 인식하기 위해 필요한 태그
        "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
        "kubernetes.io/role/elb"                        = "1"
    }
}

# 두 번째 서브넷도 인터넷에 연결되도록 라우팅 테이블 연결
resource "aws_route_table_association" "public_2_assoc" {
    subnet_id      = aws_subnet.public_2.id
    route_table_id = aws_route_table.public_rt.id
}