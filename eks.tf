module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "~> 19.0"

    cluster_name    = "${var.project_name}-eks" # 변수 사용
    cluster_version = "1.29"

    vpc_id                         = aws_vpc.main.id
    subnet_ids                     = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    cluster_endpoint_public_access = true

    eks_managed_node_groups = {
        default = {
        min_size     = 1
        max_size     = 3
        desired_size = 2
        instance_types = ["t3.medium"]
        }
    }
}