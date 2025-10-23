#!/usr/bin/env python3
"""
Infrastructure diagram for Drupal on AWS using diagrams.mingrammer.com
This visualizes the complete architecture defined in the Terraform files.

ACCURACY NOTES:
- Only HTTP (80) is enabled; HTTPS (443) listener is commented out
- Auto-scaling targets: CPU 70% (out: 60s, in: 300s), Memory 80% (out: 60s, in: 300s)
- ALB health check: Path /, interval 30s, healthy 2, unhealthy 3, timeout 5s, codes 200-399
- ECS task health check: curl -f http://localhost/, 30s interval, 5s timeout, 3 retries, 60s start period
- RDS: Auto-scales 20GB → 100GB, Multi-AZ, 7-day backups, exports error/general/slowquery logs
- Redis: Transit encryption enabled, 5-day snapshot retention
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import ELB, IGW, NATGateway, RouteTable
from diagrams.aws.compute import ECS, ECR
from diagrams.aws.database import RDS, ElastiCache
from diagrams.aws.security import SecretsManager, IAM, SecurityHub, WAF
from diagrams.aws.storage import S3
from diagrams.aws.management import Cloudwatch, CloudwatchAlarm
from diagrams.onprem.client import Client

# Create the main diagram
with Diagram("Drupal on AWS Infrastructure", show=False, filename="drupal_architecture", direction="TB"):

    # Internet and users
    users = Client("Users")
    internet = IGW("Internet")

    with Cluster("AWS VPC (10.101.0.0/16)"):
        igw = IGW("Internet Gateway")

        with Cluster("Public Subnets (AZ1: 10.101.0.0/24, AZ2: 10.101.1.0/24)"):
            pub_rt = RouteTable("Public Route Table\n(0.0.0.0/0 → IGW)")
            nat_az1 = NATGateway("NAT Gateway AZ1\n(EIP)")
            nat_az2 = NATGateway("NAT Gateway AZ2\n(EIP)")
            alb = ELB("ALB\n(HTTP 80 only)\nTarget: ECS")
            alb_sg = SecurityHub("ALB SG\nIngress: 80\nEgress: All")
            waf = WAF("WAFv2\n(Attached to ALB)\nRules: Core, Known Bad,\nSQLi, Rate Limit 2k/5m")

        with Cluster("Private Subnets (AZ1: 10.101.10.0/24, AZ2: 10.101.11.0/24)"):
            priv_rt_az1 = RouteTable("Private RT AZ1\n(0.0.0.0/0 → NAT-AZ1)")
            priv_rt_az2 = RouteTable("Private RT AZ2\n(0.0.0.0/0 → NAT-AZ2)")
            with Cluster("ECS Fargate Cluster\n(Container Insights enabled)"):
                ecs_service = ECS("Drupal ECS\n(1-3 Fargate tasks)\nCPU: 1vCPU, Mem: 2GB\nHealth: curl /")
                ecr = ECR("ECR Repo\n(drupal:latest)\nScan on push")
            ecs_sg = SecurityHub("ECS SG\nIngress: 80\n(from ALB SG)\nEgress: All")

        with Cluster("Database Subnets (AZ1: 10.101.20.0/24, AZ2: 10.101.21.0/24)"):
            db_rt = RouteTable("Database RT\n(Isolated)")
            rds = RDS("RDS MySQL 8.0\n(Multi-AZ)\ndb.t4g.micro\n20GB → 100GB\nBackup: 7d")
            rds_sg = SecurityHub("RDS SG\nIngress: 3306\n(from ECS SG)\nEgress: Denied")
            redis = ElastiCache("Redis 7.0\ncache.t4g.micro\nTransit encrypt: ON\nSnapshot: 5d")
            redis_sg = SecurityHub("Redis SG\nIngress: 6379\n(from ECS SG)\nEgress: Denied")

        with Cluster("Support Services"):
            secrets = SecretsManager("Secrets Manager\n(7d recovery)\n- DB Password\n- Redis Auth\n- Drupal Salt")
            logs = Cloudwatch("CloudWatch Logs\n/ecs (7d), /aws/waf (30d),\n/aws/alb (14d)")
            iam_role = IAM("IAM Roles\n(Exec & Task)\nSSM Session Mgr")
            alarms = CloudwatchAlarm("6 CloudWatch Alarms\n- Task count\n- ECS CPU > 90%\n- RDS CPU > 80%\n- ALB unhealthy\n- WAF blocked > 100")

    s3_logs = S3("S3 Bucket\n(ALB logs)")
    autoscaling = ECS("Auto Scaling\nCPU: 70% target\nMem: 80% target\nOut: 60s, In: 300s")

    # Internet traffic flow
    users >> Edge(label="HTTP") >> internet >> igw
    igw >> Edge(label="0.0.0.0/0") >> pub_rt
    pub_rt >> alb_sg >> alb
    alb >> Edge(label="WAFv2 Web ACL") >> waf

    # ALB health check
    alb >> Edge(label="Health: GET / every 30s\n(200-399, 2 healthy, 3 unhealthy)") >> ecs_sg

    # ALB to ECS traffic
    alb >> Edge(label="Forward to port 80") >> ecs_sg
    ecs_sg >> ecs_service

    # Outbound internet access via NAT
    ecs_service >> Edge(label="Outbound traffic\n(pkg updates)") >> priv_rt_az1
    priv_rt_az1 >> Edge(label="0.0.0.0/0") >> nat_az1
    nat_az1 >> Edge(label="SNAT") >> igw

    # ECR image pulls
    ecs_service >> Edge(label="Pull image\n(IAM auth)") >> ecr

    # Database connections
    ecs_service >> Edge(label="TCP 3306\n(MySQL)") >> rds_sg
    rds_sg >> rds
    ecs_service >> Edge(label="TCP 6379\n(Redis, TLS)") >> redis_sg
    redis_sg >> redis

    # Secrets retrieval
    ecs_service >> Edge(label="Retrieve at launch") >> secrets

    # Logging
    ecs_service >> Edge(label="Container logs\n(awslogs driver)") >> logs
    alb >> Edge(label="Access logs") >> s3_logs
    waf >> Edge(label="WAF logs\n(keep allowed, drop blocked)") >> logs

    # Monitoring
    ecs_service >> Edge(label="Metrics") >> alarms
    alb >> Edge(label="Metrics") >> alarms
    rds >> Edge(label="Metrics") >> alarms
    redis >> Edge(label="Metrics") >> alarms

    # Auto scaling
    alarms >> Edge(label="Triggers (CPU/Memory)") >> autoscaling
    autoscaling >> ecs_service

    # IAM usage
    ecs_service >> Edge(label="Task role") >> iam_role
    ecr >> iam_role


if __name__ == "__main__":
    print("Infrastructure diagram generated successfully!")
    print("Output files:")
    print("  - drupal_architecture.png (diagram image)")
    print("  - drupal_architecture (Graphviz dot file)")
