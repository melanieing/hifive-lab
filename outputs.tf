# VPC 관련 출력
output "vpc_id" {
    value       = aws_vpc.main.id
    description = "생성된 VPC ID"
}

output "public_subnet_id" {
    value       = aws_subnet.public_1.id
    description = "생성된 퍼블릭 서브넷 ID"
}

# EC2 관련 출력
output "ec2_public_ip" {
    value       = aws_instance.app_server.public_ip
    description = "EC2 인스턴스의 공인 IP"
}

# 백엔드(S3/DynamoDB) 관련 출력
output "s3_bucket_name" {
    value       = aws_s3_bucket.terraform_state.bucket
    description = "Terraform State가 저장될 S3 버킷 이름"
}

output "dynamodb_table_name" {
    value       = aws_dynamodb_table.terraform_locks.name
    description = "State Locking을 위한 DynamoDB 테이블 이름"
}

# ECR 주소 출력
output "ecr_repository_url" {
    value = aws_ecr_repository.hifive_repo.repository_url
    description = "생성된 ECR 리포지토리의 URL"
}