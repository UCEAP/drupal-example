#!/usr/bin/env python3
"""
Infrastructure diagram for Drupal on AWS using diagrams.mingrammer.com
This visualizes the complete architecture defined in the Terraform files.

To generate the diagram, run:
  python3 -m venv my_diagrams_env
  source my_diagrams_env/bin/activate
  pip install diagrams
  python3 infrastructure_diagram.py

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

# Create the main diagram with strict ranking
with Diagram("Drupal on AWS Infrastructure", show=False, filename="drupal_architecture", direction="TB"):

    # Internet and users (TOP)
    users = Client("Users")

    with Cluster("AWS VPC (10.101.0.0/16)"):
        # Layer 1: Internet Gateway
        igw = IGW("Internet Gateway")

        # Layer 2: Availability Zones (side by side)
        with Cluster("Availability Zone 1"):
            nat_az1 = NATGateway("NAT Gateway AZ1\n(EIP)")
            priv_rt_az1 = RouteTable("Private RT\n(0.0.0.0/0 → NAT)")
            ecs_az1 = ECS("Drupal ECS Task\nCPU: 1vCPU, Mem: 2GB\nHealth: curl /")
            rds_az1 = RDS("RDS Primary\nMySQL 8.0\ndb.t4g.micro")
            redis_az1 = ElastiCache("Redis Primary\n7.0\ncache.t4g.micro")

        with Cluster("Availability Zone 2"):
            nat_az2 = NATGateway("NAT Gateway AZ2\n(EIP)")
            priv_rt_az2 = RouteTable("Private RT\n(0.0.0.0/0 → NAT)")
            ecs_az2 = ECS("Drupal ECS Task\nCPU: 1vCPU, Mem: 2GB\nHealth: curl /")
            rds_az2 = RDS("RDS Standby\nMySQL 8.0\n(Multi-AZ)\n20GB → 100GB\nBackup: 7d")
            redis_az2 = ElastiCache("Redis Replica\nTransit encrypt: ON\nSnapshot: 5d")

        # Layer 3: Regional resources (ALB, WAF)
        with Cluster("Regional Resources"):
            alb = ELB("ALB\n(HTTP 80 only)\nTarget: ECS")
            waf = WAF("WAFv2\n(Attached to ALB)\nRules: Core, Known Bad,\nSQLi, Rate Limit 2k/5m")
            alb_sg = SecurityHub("ALB SG\nIngress: 80\nEgress: All")
            pub_rt = RouteTable("Public Route Table\n(0.0.0.0/0 → IGW)")

        # Layer 4: Support Services (BOTTOM)
        with Cluster("Support Services"):
            ecs_sg = SecurityHub("ECS SG\nIngress: 80\n(from ALB SG)\nEgress: All")
            rds_sg = SecurityHub("RDS SG\nIngress: 3306\n(from ECS SG)\nEgress: Denied")
            redis_sg = SecurityHub("Redis SG\nIngress: 6379\n(from ECS SG)\nEgress: Denied")
            secrets = SecretsManager("Secrets Manager\n(7d recovery)\n- DB Password\n- Redis Auth\n- Drupal Salt")
            logs = Cloudwatch("CloudWatch Logs\n/ecs (7d), /aws/waf (30d),\n/aws/alb (14d)")
            iam_role = IAM("IAM Roles\n(Exec & Task)\nSSM Session Mgr")
            alarms = CloudwatchAlarm("6 CloudWatch Alarms\n- Task count\n- ECS CPU > 90%\n- RDS CPU > 80%\n- ALB unhealthy\n- WAF blocked > 100")
            ecr = ECR("ECR Repo\n(drupal:latest)\nScan on push")

        s3_logs = S3("S3 Bucket\n(ALB logs)")
        autoscaling = ECS("Auto Scaling\nCPU: 70% target\nMem: 80% target\nOut: 60s, In: 300s")

    # Internet traffic flow (TOP to BOTTOM)
    users >> Edge(label="HTTP") >> igw
    igw >> Edge(label="0.0.0.0/0") >> pub_rt
    pub_rt >> alb_sg >> alb
    alb >> Edge(label="WAFv2 Web ACL") >> waf

    # ALB health check and traffic to ECS (both AZs)
    alb >> Edge(label="Health: GET / every 30s\n(200-399, 2 healthy, 3 unhealthy)") >> ecs_sg
    alb >> Edge(label="Forward to port 80") >> ecs_sg
    ecs_sg >> ecs_az1
    ecs_sg >> ecs_az2

    # Outbound internet access via NAT (AZ1)
    ecs_az1 >> Edge(label="Outbound\n(pkg updates)") >> priv_rt_az1
    priv_rt_az1 >> Edge(label="0.0.0.0/0") >> nat_az1
    nat_az1 >> Edge(label="SNAT") >> igw

    # Outbound internet access via NAT (AZ2)
    ecs_az2 >> Edge(label="Outbound\n(pkg updates)") >> priv_rt_az2
    priv_rt_az2 >> Edge(label="0.0.0.0/0") >> nat_az2
    nat_az2 >> Edge(label="SNAT") >> igw

    # ECR image pulls
    ecs_az1 >> Edge(label="Pull image\n(IAM auth)") >> ecr
    ecs_az2 >> Edge(label="Pull image\n(IAM auth)") >> ecr

    # Database connections (AZ1)
    ecs_az1 >> Edge(label="TCP 3306") >> rds_sg
    rds_sg >> rds_az1
    ecs_az1 >> Edge(label="TCP 6379\n(TLS)") >> redis_sg
    redis_sg >> redis_az1

    # Database connections (AZ2)
    ecs_az2 >> Edge(label="TCP 3306") >> rds_sg
    rds_sg >> rds_az2
    ecs_az2 >> Edge(label="TCP 6379\n(TLS)") >> redis_sg
    redis_sg >> redis_az2

    # RDS Multi-AZ replication
    rds_az1 >> Edge(label="Synchronous\nreplication") >> rds_az2

    # Redis replication
    redis_az1 >> Edge(label="Asynchronous\nreplication") >> redis_az2

    # Secrets retrieval
    ecs_az1 >> Edge(label="Retrieve at launch") >> secrets
    ecs_az2 >> Edge(label="Retrieve at launch") >> secrets

    # Logging
    ecs_az1 >> Edge(label="Container logs\n(awslogs driver)") >> logs
    ecs_az2 >> Edge(label="Container logs\n(awslogs driver)") >> logs
    alb >> Edge(label="Access logs") >> s3_logs
    waf >> Edge(label="WAF logs\n(keep allowed, drop blocked)") >> logs

    # Monitoring
    ecs_az1 >> Edge(label="Metrics") >> alarms
    ecs_az2 >> Edge(label="Metrics") >> alarms
    alb >> Edge(label="Metrics") >> alarms
    rds_az1 >> Edge(label="Metrics") >> alarms
    rds_az2 >> Edge(label="Metrics") >> alarms
    redis_az1 >> Edge(label="Metrics") >> alarms
    redis_az2 >> Edge(label="Metrics") >> alarms

    # Auto scaling
    alarms >> Edge(label="Triggers (CPU/Memory)") >> autoscaling
    autoscaling >> ecs_az1
    autoscaling >> ecs_az2

    # IAM usage
    ecs_az1 >> Edge(label="Task role") >> iam_role
    ecs_az2 >> Edge(label="Task role") >> iam_role
    ecr >> iam_role


if __name__ == "__main__":
    print("Infrastructure diagram generated successfully!")
    print("Output files:")
    print("  - drupal_architecture.png (diagram image)")
    print("  - drupal_architecture (Graphviz dot file)")
