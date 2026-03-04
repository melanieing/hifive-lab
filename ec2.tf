# 보안 그룹 생성 (방화벽)
resource "aws_security_group" "hifive_sg" {
    name        = "${var.project_name}-sg"
    description = "Allow SSH and HTTP traffic"
    vpc_id      = aws_vpc.main.id

    # 인바운드 규칙: SSH 접속 (22번 포트)
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # 실무에서는 본인 IP만 허용하는 게 정석입니다.
    }

    # 인바운드 규칙: HTTP 접속 (80번 포트)
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # 아웃바운드 규칙: 외부로 나가는 모든 트래픽 허용
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-sg"
    }
}

# 최신 Amazon Linux 2023 AMI ID 가져오기 (데이터 소스)
data "aws_ami" "amazon_linux_2023" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["al2023-ami-2023*-x86_64"]
    }
}

# EC2 인스턴스 생성
resource "aws_instance" "app_server" {
    ami           = data.aws_ami.amazon_linux_2023.id
    instance_type = "t3.micro" # 프리티어 대상 (상황에 따라 t2.micro)

    subnet_id                   = aws_subnet.public_1.id
    vpc_security_group_ids      = [aws_security_group.hifive_sg.id]
    associate_public_ip_address = true

    # 역할 연결
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

    # 사용자 데이터 (EC2 생성 시 자동 실행될 스크립트 - 웹서버 설치)
    user_data = <<-EOF
            #!/bin/bash
            # 1. 도커 설치 및 실행
            dnf update -y
            dnf install -y docker
            systemctl start docker
            systemctl enable docker
            
            # 2. ec2-user에게 도커 권한 부여
            usermod -aG docker ec2-user
            
            # 3. ECR 로그인 및 이미지 실행
            aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.hifive_repo.repository_url}
            docker run -d -p 80:80 ${aws_ecr_repository.hifive_repo.repository_url}:latest
            EOF

    tags = {
        Name = "${var.project_name}-app-server"
    }
}

# ECR 리포지토리 생성
resource "aws_ecr_repository" "hifive_repo" {
    name                 = "hifive-web-app"
    image_tag_mutability = "MUTABLE"

    image_scanning_configuration {
        scan_on_push = true # 이미지를 올릴 때 보안 취약점을 자동으로 스캔합니다.
    }
}

# EC2가 사용할 IAM 역할 생성
resource "aws_iam_role" "ec2_role" {
    name = "${var.project_name}-ec2-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17" # "최신 IAM 문법 규칙을 사용"
        Statement = [
        {
            Action = "sts:AssumeRole" # "이 역할을 누군가 가져가서 사용하는 걸 허용할 건데"
            Effect = "Allow"
            Principal = {
            Service = "ec2.amazonaws.com" # "그 누군가는 바로 EC2 서비스야"
            }
        }
        ]
    })
}

# 2. 역할에 ECR 읽기 권한 정책 연결
resource "aws_iam_role_policy_attachment" "ecr_read" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 3. EC2 인스턴스에 역할을 부여하기 위한 프로파일
resource "aws_iam_instance_profile" "ec2_profile" {
    name = "${var.project_name}-ec2-profile"
    role = aws_iam_role.ec2_role.name
}