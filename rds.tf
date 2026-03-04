# 1. DB용 보안 그룹 (EC2나 EKS 노드에서만 접근 가능하도록 설정)
resource "aws_security_group" "db_sg" {
    name        = "${var.project_name}-db-sg"
    description = "Allow database traffic from application"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 5432 # PostgreSQL 포트
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = [aws_vpc.main.cidr_block] # VPC 내부 통신만 허용
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-db-sg"
    }
}

# 2. DB용 서브넷 그룹 (일관성 있게 public_1, public_2 사용)
resource "aws_db_subnet_group" "main" {
    name       = "${var.project_name}-db-subnet-group"
    subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]

    tags = {
        Name = "${var.project_name}-db-subnet-group"
    }
}

# 3. Aurora PostgreSQL 클러스터
resource "aws_rds_cluster" "aurora" {
    cluster_identifier      = "${var.project_name}-aurora"
    engine                  = "aurora-postgresql"
    engine_version          = "15.4"
    database_name           = "hifivedb"
    master_username         = "admin"
    master_password         = "hifive1234!" # 실습용 비밀번호
    
    db_subnet_group_name    = aws_db_subnet_group.main.name
    vpc_security_group_ids  = [aws_security_group.db_sg.id]
    
    skip_final_snapshot     = true # 삭제 시 비용 발생하는 스냅샷 생성을 건너뜀
    deletion_protection     = false # 실습용이므로 즉시 삭제 가능하게 설정
}

# 4. Aurora 클러스터 인스턴스 (비용 절감을 위해 딱 1개만 생성)
resource "aws_rds_cluster_instance" "aurora_instances" {
    identifier         = "${var.project_name}-aurora-instance"
    cluster_identifier = aws_rds_cluster.aurora.id
    instance_class     = "db.t3.medium" # Aurora 최소 사양
    engine             = aws_rds_cluster.aurora.engine
    engine_version     = aws_rds_cluster.aurora.engine_version
    
    publicly_accessible = false # 보안을 위해 외부 접속 차단
}