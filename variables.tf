variable "region" {
    description = "AWS 리전"
    type = string
    default = "ap-northeast-2"
}

variable "project_name" {
    description = "프로젝트 이름 태그"
    type        = string
    default     = "hifive-lab"
}

variable "vpc_cidr" {
    description = "VPC CIDR 블록"
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
    description = "퍼블릭 서브넷 CIDR 블록"
    type = string
    default ="10.0.1.0/24" 
}