terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
    required_version = ">= 1.2.0"

    # 2. 원격 백엔드 설정 (이 부분이 이사 갈 주소)
#     backend "s3" {
#         bucket         = "hifive-lab-tfstate-4v2r6p06"
#         key            = "terraform/state/hifive-lab.tfstate" # S3 내부 저장 경로
#         region         = "ap-northeast-2"
#         dynamodb_table = "hifive-lab-tflocks" # Lock을 위한 테이블명
#         encrypt        = true                 # 상태 파일 암호화 여부
#   }
}

provider "aws" {
    region = var.region # 변수 사용
}