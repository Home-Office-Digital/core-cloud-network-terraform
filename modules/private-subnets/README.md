# Terraform Module: private-subnets

This module creates private `/27` subnets in a selected VPC, plus per-subnet routing and endpoint associations.

## What It Creates

- Private subnets using index-based `cidrsubnet` allocation.
- One route table per subnet with default route to the configured TGW.
- Route table associations for each subnet.
- S3 and DynamoDB VPC endpoint route table associations.
- One private NAT gateway per subnet.
- Optional `VpcName` tag on the VPC.

## Behavior Notes

- VPC is discovered by `Name` tag (`vpc_name` input).
- Subnet target size is `/27`.
- Current subnet indexes are `[2, 3, 4]`.
- Indexes that exceed the calculated subnet range are filtered out.
- Availability zones are currently mapped statically to `eu-west-2a/b/c`.

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `vpc_name` | `string` | yes | Name tag of the target VPC. |
| `tags` | `map(string)` | yes | Common tags merged into created resources. |
| `eks_cluster1_name` | `string` | yes | Optional EKS cluster name for ownership tag; pass empty string to skip. |
| `eks_cluster2_name` | `string` | yes | Optional EKS cluster name for ownership tag; pass empty string to skip. |
| `tgw_id` | `string` | yes | Transit Gateway ID used for route table default route. |
| `tag_vpc_name` | `string` | no | Optional value for `VpcName` tag on the VPC. Defaults to empty string. |

## Outputs

| Name | Description |
|---|---|
| `subnet_names_and_cidrs` | Map keyed by subnet name with subnet `name`, `cidr`, and `id`. |

## Usage

```hcl
module "private_subnets" {
  source = "./modules/private-subnets"

  vpc_name          = "workload-dev-vpc"
  eks_cluster1_name = "eks-main"
  eks_cluster2_name = ""
  tgw_id            = "tgw-0123456789abcdef0"
  tag_vpc_name      = "workload-dev-vpc"

  tags = {
    project_id  = "CORECLOUD"
    environment = "dev"
  }
}
```

## Run Tests Locally

From this module directory:

```bash
terraform init
terraform test
```

Optional:

```bash
terraform fmt -check -recursive
terraform validate
```
