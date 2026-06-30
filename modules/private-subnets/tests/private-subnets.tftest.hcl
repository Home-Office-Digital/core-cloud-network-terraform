mock_provider "aws" {}

run "private_subnets_default_plan" {
  command = plan

  variables {
    vpc_name          = "workload-dev-vpc"
    eks_cluster1_name = "eks-main"
    eks_cluster2_name = "eks-tools"
    tgw_id            = "tgw-0123456789abcdef0"
    tag_vpc_name      = "workload-vpc"
    tags = {
      environment = "dev"
      owner       = "platform"
    }
  }

  override_data {
    target = data.aws_vpcs.filtered_vpcs
    values = {
      ids = ["vpc-0123456789abcdef0"]
    }
  }

  override_data {
    target = data.aws_vpc.selected
    values = {
      id         = "vpc-0123456789abcdef0"
      cidr_block = "10.0.0.0/20"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.s3
    values = {
      id = "vpce-s3-1234"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.dynamodb
    values = {
      id = "vpce-ddb-1234"
    }
  }

  assert {
    condition     = length(aws_subnet.private) == 3
    error_message = "Expected 3 private subnets for /20 VPC CIDR"
  }

  assert {
    condition     = aws_subnet.private[0].cidr_block == "10.0.0.64/27" && aws_subnet.private[1].cidr_block == "10.0.0.96/27" && aws_subnet.private[2].cidr_block == "10.0.0.128/27"
    error_message = "Expected subnet CIDR sequence for indexes [2,3,4]"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.private :
      subnet.tags["kubernetes.io/role/internal-elb"] == "1"
    ])
    error_message = "Every subnet must have internal ELB tag"
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.private :
      subnet.tags["kubernetes.io/cluster/eks-main"] == "owned" && subnet.tags["kubernetes.io/cluster/eks-tools"] == "owned"
    ])
    error_message = "Expected optional EKS ownership tags to be present when names are provided"
  }

  assert {
    condition     = length(aws_route_table.main_private_subnet_route_tables) == 3 && length(aws_route_table_association.main_private_subnets_association) == 3
    error_message = "Each subnet should have one route table and one association"
  }

  assert {
    condition     = length(aws_vpc_endpoint_route_table_association.main_private_subnets_private_s3) == 3 && length(aws_vpc_endpoint_route_table_association.main_private_subnets_private_dynamodb) == 3
    error_message = "Each route table should be associated to both S3 and DynamoDB endpoints"
  }

  assert {
    condition = length(aws_nat_gateway.private_nat_gw) == 3 && alltrue([
      for nat in values(aws_nat_gateway.private_nat_gw) :
      nat.connectivity_type == "private"
    ])
    error_message = "Expected one private NAT gateway per subnet"
  }

  assert {
    condition     = aws_subnet.private[0].availability_zone == "eu-west-2a" && aws_subnet.private[1].availability_zone == "eu-west-2b" && aws_subnet.private[2].availability_zone == "eu-west-2c"
    error_message = "Expected static AZ spread across eu-west-2a/b/c"
  }

  assert {
    condition = alltrue([
      for rt in values(aws_route_table.main_private_subnet_route_tables) :
      contains([
        for route in tolist(rt.route) :
        route.cidr_block
        ], "0.0.0.0/0") && contains([
        for route in tolist(rt.route) :
        route.transit_gateway_id
      ], "tgw-0123456789abcdef0")
    ])
    error_message = "Expected default route to TGW in each private route table"
  }

  assert {
    condition     = aws_ec2_tag.tag-vpc-name[0].value == "workload-vpc"
    error_message = "Expected VpcName tag resource when tag_vpc_name is set"
  }
}

run "private_subnets_small_vpc_bounds" {
  command = plan

  variables {
    vpc_name          = "workload-small-vpc"
    eks_cluster1_name = ""
    eks_cluster2_name = ""
    tgw_id            = "tgw-0123456789abcdef0"
    tag_vpc_name      = ""
    tags = {
      environment = "test"
    }
  }

  override_data {
    target = data.aws_vpcs.filtered_vpcs
    values = {
      ids = ["vpc-0fedcba9876543210"]
    }
  }

  override_data {
    target = data.aws_vpc.selected
    values = {
      id         = "vpc-0fedcba9876543210"
      cidr_block = "10.2.0.0/26"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.s3
    values = {
      id = "vpce-s3-5678"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.dynamodb
    values = {
      id = "vpce-ddb-5678"
    }
  }

  assert {
    condition     = length(aws_subnet.private) == 0 && length(aws_route_table.main_private_subnet_route_tables) == 0 && length(aws_nat_gateway.private_nat_gw) == 0
    error_message = "Expected zero created resources when subnet indexes exceed max subnets"
  }
}

run "private_subnets_optional_eks_tags_absent" {
  command = plan

  variables {
    vpc_name          = "workload-no-eks-vpc"
    eks_cluster1_name = ""
    eks_cluster2_name = ""
    tgw_id            = "tgw-0123456789abcdef0"
    tag_vpc_name      = ""
    tags = {
      environment = "qa"
    }
  }

  override_data {
    target = data.aws_vpcs.filtered_vpcs
    values = {
      ids = ["vpc-00112233445566778"]
    }
  }

  override_data {
    target = data.aws_vpc.selected
    values = {
      id         = "vpc-00112233445566778"
      cidr_block = "10.4.0.0/20"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.s3
    values = {
      id = "vpce-s3-9012"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.dynamodb
    values = {
      id = "vpce-ddb-9012"
    }
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.private :
      !contains(keys(subnet.tags), "kubernetes.io/cluster/")
    ])
    error_message = "Unexpected empty-key EKS cluster tag found when cluster names are blank"
  }

  assert {
    condition     = length(aws_ec2_tag.tag-vpc-name) == 0
    error_message = "VpcName tag resource should not be created when tag_vpc_name is empty"
  }
}

run "private_subnets_trimmed_vpc_tag" {
  command = plan

  variables {
    vpc_name          = "workload-trim-vpc"
    eks_cluster1_name = ""
    eks_cluster2_name = ""
    tgw_id            = "tgw-0123456789abcdef0"
    tag_vpc_name      = "  prod-core-vpc  "
    tags = {
      environment = "prod"
    }
  }

  override_data {
    target = data.aws_vpcs.filtered_vpcs
    values = {
      ids = ["vpc-8899aabbccddeeff0"]
    }
  }

  override_data {
    target = data.aws_vpc.selected
    values = {
      id         = "vpc-8899aabbccddeeff0"
      cidr_block = "10.8.0.0/20"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.s3
    values = {
      id = "vpce-s3-3456"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.dynamodb
    values = {
      id = "vpce-ddb-3456"
    }
  }

  assert {
    condition     = length(aws_ec2_tag.tag-vpc-name) == 1 && aws_ec2_tag.tag-vpc-name[0].value == "prod-core-vpc"
    error_message = "Expected trimmed VpcName value when tag_vpc_name includes surrounding spaces"
  }
}

run "private_subnets_partial_capacity_vpc_bounds" {
  command = plan

  variables {
    vpc_name          = "workload-partial-vpc"
    eks_cluster1_name = ""
    eks_cluster2_name = ""
    tgw_id            = "tgw-0123456789abcdef0"
    tag_vpc_name      = ""
    tags = {
      environment = "test"
    }
  }

  override_data {
    target = data.aws_vpcs.filtered_vpcs
    values = {
      ids = ["vpc-11223344556677889"]
    }
  }

  override_data {
    target = data.aws_vpc.selected
    values = {
      id         = "vpc-11223344556677889"
      cidr_block = "10.9.0.0/25"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.s3
    values = {
      id = "vpce-s3-7777"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.dynamodb
    values = {
      id = "vpce-ddb-7777"
    }
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Expected only 2 subnets for /25 because index 4 exceeds allowed subnet range"
  }

  assert {
    condition     = length(aws_route_table.main_private_subnet_route_tables) == 2 && length(aws_nat_gateway.private_nat_gw) == 2
    error_message = "Expected route tables and NAT gateways to match reduced subnet count"
  }
}

run "private_subnets_whitespace_only_vpc_tag" {
  command = plan

  variables {
    vpc_name          = "workload-space-vpc"
    eks_cluster1_name = ""
    eks_cluster2_name = ""
    tgw_id            = "tgw-0123456789abcdef0"
    tag_vpc_name      = "    "
    tags = {
      environment = "test"
    }
  }

  override_data {
    target = data.aws_vpcs.filtered_vpcs
    values = {
      ids = ["vpc-aabbccddeeff00112"]
    }
  }

  override_data {
    target = data.aws_vpc.selected
    values = {
      id         = "vpc-aabbccddeeff00112"
      cidr_block = "10.10.0.0/20"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.s3
    values = {
      id = "vpce-s3-8888"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.dynamodb
    values = {
      id = "vpce-ddb-8888"
    }
  }

  assert {
    condition     = length(aws_ec2_tag.tag-vpc-name) == 0
    error_message = "Expected no VpcName tag resource when input is only whitespace"
  }
}

run "private_subnets_single_eks_tag_only" {
  command = plan

  variables {
    vpc_name          = "workload-single-eks-vpc"
    eks_cluster1_name = "eks-main"
    eks_cluster2_name = ""
    tgw_id            = "tgw-0123456789abcdef0"
    tag_vpc_name      = ""
    tags = {
      environment = "dev"
    }
  }

  override_data {
    target = data.aws_vpcs.filtered_vpcs
    values = {
      ids = ["vpc-22334455667788990"]
    }
  }

  override_data {
    target = data.aws_vpc.selected
    values = {
      id         = "vpc-22334455667788990"
      cidr_block = "10.11.0.0/20"
    }
  }

  override_data {
    target = data.aws_region.current
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.s3
    values = {
      id = "vpce-s3-9999"
    }
  }

  override_data {
    target = data.aws_vpc_endpoint.dynamodb
    values = {
      id = "vpce-ddb-9999"
    }
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.private :
      contains(keys(subnet.tags), "kubernetes.io/cluster/eks-main") && !contains(keys(subnet.tags), "kubernetes.io/cluster/")
    ])
    error_message = "Expected only the configured EKS cluster tag and no empty-key cluster tag"
  }
}