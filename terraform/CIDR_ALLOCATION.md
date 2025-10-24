# CIDR Allocation Registry

## 10.0.0.0/8 - Internal Infrastructure Space

This document tracks IP address allocation for all internal applications and infrastructure.

## CIDR Block Allocation

| CIDR Block      | Purpose                          | Status   | Notes |
|-----------------|----------------------------------|----------|-------|
| 10.0.0.0/16     | Shared Services (Reserved)       | Reserved | VPN, monitoring, shared infrastructure |
| 10.1.0.0/16 - 10.100.0.0/16 | Additional shared infrastructure | Reserved | Future use |
| 10.101.0.0/16   | drupal-example (app_number=101)  | Active   | Drupal CMS application |
| 10.102.0.0/16   | (Next app, app_number=102)       | Available |  |
| 10.103.0.0/16   | (Next app, app_number=103)       | Available |  |
| ...             | ...                              | Available |  |
| 10.254.0.0/16   | (Last app, app_number=254)       | Available |  |

## Application VPC Subnet Structure

Each application VPC uses a consistent internal structure for predictable IP allocation.

### Example: drupal-example (10.101.0.0/16)

| CIDR Block      | Tier     | AZ     | Use Case       | Hosts | Gateway |
|-----------------|----------|--------|----------------|-------|---------|
| 10.101.0.0/24   | Public   | us-west-2a | ALB            | ~254  | IGW     |
| 10.101.1.0/24   | Public   | us-west-2b | ALB (HA)       | ~254  | IGW     |
| 10.101.10.0/24  | Private  | us-west-2a | ECS Tasks      | ~254  | NAT-GW  |
| 10.101.11.0/24  | Private  | us-west-2b | ECS Tasks (HA) | ~254  | NAT-GW  |
| 10.101.20.0/24  | Database | us-west-2a | RDS/Redis      | ~254  | None    |
| 10.101.21.0/24  | Database | us-west-2b | RDS/Redis (HA) | ~254  | None    |

### Template for New Apps

When deploying a new application, use this template with your assigned `app_number`:

| CIDR Block          | Tier     | AZ     | Use Case       |
|---------------------|----------|--------|----------------|
| 10.{app_number}.0.0/24   | Public   | AZ1    | Load Balancer  |
| 10.{app_number}.1.0/24   | Public   | AZ2    | Load Balancer  |
| 10.{app_number}.10.0/24  | Private  | AZ1    | Application    |
| 10.{app_number}.11.0/24  | Private  | AZ2    | Application    |
| 10.{app_number}.20.0/24  | Database | AZ1    | Data Layer     |
| 10.{app_number}.21.0/24  | Database | AZ2    | Data Layer     |

## Network Tiers

### Public Tier (X.0.0/24, X.1.0/24)
- Internet-facing resources (ALB, NAT gateways)
- Ingress from internet allowed
- Routed through Internet Gateway

### Private Tier (X.10.0/24, X.11.0/24)
- Application compute (ECS tasks)
- No direct internet access
- Egress through NAT Gateway for outbound internet access
- Ingress only from ALB

### Database Tier (X.20.0/24, X.21.0/24)
- Data layer resources (RDS, ElastiCache)
- No internet access
- Ingress only from application tier
- No outbound internet access

## Deployment Instructions

To deploy a new application with this convention:

1. **Assign an app_number**: Choose a number between 101-254 (update this registry first)
2. **Update this registry**: Add the app and its status
3. **Deploy with Terraform**:
   ```bash
   terraform apply -var="app_number=101"  # For drupal-example
   terraform apply -var="app_number=102"  # For next app
   ```

4. **Verify CIDR blocks** in AWS console match expected values

## Benefits

- **Predictable**: Each app's CIDR space is deterministic and easy to calculate
- **Readable**: Simple numeric offsets (0, 1, 10, 11, 20, 21) are easy to remember
- **Scalable**: Supports up to 154 applications
- **Reserved**: Lower CIDR space (10.0-10.100) reserved for shared infrastructure
- **Non-overlapping**: Each app completely isolated in its own /16
