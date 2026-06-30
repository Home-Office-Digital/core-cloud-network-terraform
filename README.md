# core-cloud-network-terraform

Terraform modules for core cloud networking resources.

## Directory Structure

```plaintext
modules/
└── private-subnets/
    ├── data.tf
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    ├── README.md
    └── tests/
        └── private-subnets.tftest.hcl
```

## Modules

- `private-subnets`: Creates private /27 subnets, route tables, endpoint route associations, and private NAT gateways in a selected VPC.

## Run Tests Locally

From the module directory:

```bash
cd modules/private-subnets
terraform init
terraform test
```

Optional validation commands:

```bash
terraform fmt -check -recursive
terraform validate
```
