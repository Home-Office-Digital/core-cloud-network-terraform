---
name: core-cloud-network-terraform
description: 'Understand, review, and modify the core-cloud-network-terraform repository. Use for private subnet module changes, Terraform input/output updates, route table and VPC endpoint wiring checks, and README consistency checks.'
argument-hint: 'What repo task should be performed (for example: update subnet sizing, add tags, review module behavior)?'
user-invocable: true
---

# Core Cloud Network Terraform Workflow

## What This Skill Produces
- Safe, implementation-first updates to the `modules/private-subnets` Terraform module.
- A short change report covering behavioral impact and validation status.
- Follow-up checks only where risk remains.

## When To Use
- You need to change subnet creation behavior in `modules/private-subnets`.
- You need to adjust route table, TGW, NAT gateway, or VPC endpoint associations.
- You need to add or modify module variables/outputs and keep docs aligned.
- You need a quick repo information pass before making changes.

## Repository Facts To Anchor On
- Active module path is `modules/private-subnets`.
- Data discovery is defined in `modules/private-subnets/data.tf`.
- Main resources are defined in `modules/private-subnets/main.tf`.
- Inputs and outputs are in `modules/private-subnets/variables.tf` and `modules/private-subnets/outputs.tf`.
- Root `README.md` may mention modules not currently present. Verify before relying on it.

## Procedure
1. Confirm the requested outcome.
2. Read the current module files (`data.tf`, `main.tf`, `variables.tf`, `outputs.tf`, module `README.md`) before editing.
3. Map impact first:
   - Inputs: which variables are required, optional, or newly needed.
   - Resource behavior: subnet count/indexing, AZ mapping, routing, endpoints, NAT gateways.
   - Outputs/docs: what users of the module observe externally.
4. Implement the smallest safe change set immediately after impact mapping.
5. Re-check Terraform logic for consistency and common regressions.
6. Update module docs (and root docs if relevant) only when behavior, inputs, or outputs changed.
7. Provide a concise completion summary with risks and follow-up validation commands.

## Decision Points
- Subnet math changes:
  - If requested CIDR target changes, recompute `newbits` and verify subnet index bounds.
  - If index list changes, ensure indexes are less than the computed max subnet count.
- AZ behavior changes:
  - Default to static-AZ-first guidance for this repository's current pattern.
  - If dynamic AZ selection is explicitly requested, replace hard-coded AZs carefully and keep name suffix logic aligned.
- Tagging changes:
  - If EKS cluster tags are optional, preserve conditional tag behavior.
  - If new tags are required, merge them without removing existing caller-provided tags.
- Routing changes:
  - If default route target changes (for example, TGW), ensure all private route tables are updated consistently.
  - If endpoint associations change, keep S3 and DynamoDB behavior explicit and symmetrical unless intentionally different.

## Completion Checks
- No dangling references after variable/resource changes.
- Subnet count and route table associations stay one-to-one.
- Output schema remains stable unless change was explicitly requested.
- README updates are required only if behavior, inputs, or outputs changed.
- Suggested validation commands are included for the user:
  - `terraform fmt -recursive`
  - `terraform validate`

## Expected Response Format
- Scope of change.
- Files changed and why.
- Behavioral impact.
- Validation performed (or commands to run).
- Remaining risks or assumptions.