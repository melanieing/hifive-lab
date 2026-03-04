# 1. S3 버킷 생성 (이름은 전 세계에서 유일해야 함)
# 테라폼의 '상태 파일(.tfstate)'을 저장하는 원격 저장소 역할
resource "aws_s3_bucket" "terraform_state" {
    bucket = "hifive-lab-tfstate-${random_string.suffix.result}" # 유일한 이름 생성

    lifecycle {
        prevent_destroy = false # 실습용이므로 삭제 가능하게 설정 (실무에선 true)
    }
}

# 2. S3 버전 관리 활성화 (실수로 지워도 복구 가능하게)
resource "aws_s3_bucket_versioning" "enabled" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

# 3. DynamoDB 테이블 생성 (Lock 용도)
# 여러 명이 동시에 terraform apply를 할 때, 한 명만 수정할 수 있도록 잠금을 걸어 충돌을 방지합니다.
resource "aws_dynamodb_table" "terraform_locks" {
    name         = "hifive-lab-tflocks"
    billing_mode = "PAY_PER_REQUEST" # 사용한 만큼만 비용 지불
    hash_key     = "LockID" # 테라폼이 잠금 상태를 확인할 때 사용하는 필수 키 값

    # 속성 정의: LockID라는 이름의 문자열(S = String) 타입 속성을 생성
    attribute {
        name = "LockID"
        type = "S"
    }
}

# 랜덤 문자열 생성 (S3 이름 중복 방지)
resource "random_string" "suffix" {
    length  = 8
    special = false # 특수문자 제외 (S3 이름 규칙 준수)
    upper   = false # 대문자 제외 (S3 이름 규칙 준수)
}