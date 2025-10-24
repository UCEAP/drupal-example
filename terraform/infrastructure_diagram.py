#!/usr/bin/env python3
"""
AWS Drupal Infrastructure Diagram Generator
Generates a Graphviz diagram from Terraform configuration
"""

from graphviz import Digraph

def create_aws_infrastructure_diagram():
    """Create a comprehensive diagram of the AWS Drupal infrastructure"""

    # Create the main graph with custom styling
    dot = Digraph(
        'AWS_Drupal_Infrastructure',
        comment='Drupal on AWS - ECS Fargate Architecture',
        format='png'
    )

    # Global graph attributes
    dot.attr(
        rankdir='TB',
        splines='polyline',
        nodesep='0.6',
        ranksep='1.0',
        fontname='Arial',
        fontsize='14',
        bgcolor='white',
        compound='true',
        newrank='true'
    )

    # Node styling defaults
    dot.attr('node',
             shape='box',
             style='rounded,filled',
             fontname='Arial',
             fontsize='11',
             margin='0.3,0.2'
    )

    # === INTERNET & ENTRY POINT ===
    dot.node('internet', 'Internet\n🌐',
             shape='ellipse',
             fillcolor='#E3F2FD',
             color='#1976D2',
             fontsize='13',
             penwidth='2')

    # === REGIONAL SERVICES (Above VPC) ===
    with dot.subgraph(name='cluster_regional') as regional:
        regional.attr(label='AWS Region US-West-2',
                     fontsize='13',
                     style='dashed',
                     color='#616161',
                     penwidth='2')

        # WAF (first line of defense)
        regional.node('waf', 'AWS WAF\n(OWASP Top 10 + Rate Limiting)',
                     fillcolor='#EF9A9A',
                     color='#C62828',
                     shape='hexagon',
                     penwidth='2')

        # === VPC ===
        with regional.subgraph(name='cluster_vpc') as vpc:
            vpc.attr(label='VPC (10.X.0.0/16)',
                    fontsize='14',
                    style='solid',
                    color='#1976D2',
                    penwidth='3',
                    bgcolor='#F5F5F5')

            # Internet Gateway (at VPC boundary)
            vpc.node('igw', 'Internet Gateway',
                    fillcolor='#64B5F6',
                    color='#1565C0',
                    penwidth='2')

            # === AVAILABILITY ZONE 1 ===
            with vpc.subgraph(name='cluster_az1') as az1:
                az1.attr(label='Availability Zone 1 (us-west-2a)',
                        fontsize='12',
                        style='solid',
                        color='#FF6F00',
                        penwidth='2')

                # Public Subnet with NAT Gateway at top
                with az1.subgraph(name='cluster_public_az1') as pub_az1:
                    pub_az1.attr(label='Public Subnet (10.X.0.0/24)',
                                fontsize='10',
                                style='filled',
                                fillcolor='#E8F4F8',
                                color='#1E88E5')
                    pub_az1.node('nat_az1', 'NAT Gateway\n(Elastic IP)',
                                fillcolor='#90CAF9',
                                color='#1565C0')
                    pub_az1.node('alb_az1', 'Application Load Balancer\n(Spans AZs)',
                                fillcolor='#64B5F6',
                                color='#1565C0',
                                shape='box3d',
                                penwidth='2')

                # Private Subnet AZ1
                with az1.subgraph(name='cluster_private_az1') as priv_az1:
                    priv_az1.attr(label='Private Subnet (10.X.10.0/24)',
                                 fontsize='10',
                                 style='filled',
                                 fillcolor='#F3E5F5',
                                 color='#8E24AA')
                    priv_az1.node('ecs_task_az1', 'ECS Tasks\n(Drupal Containers)',
                                 fillcolor='#CE93D8',
                                 color='#6A1B9A',
                                 shape='component',
                                 penwidth='2')

                # Database Subnet AZ1
                with az1.subgraph(name='cluster_db_az1') as db_az1:
                    db_az1.attr(label='Database Subnet (10.X.20.0/24)',
                               fontsize='10',
                               style='filled',
                               fillcolor='#FFF3E0',
                               color='#F57C00')
                    db_az1.node('rds_az1', 'RDS MySQL\n(Primary)',
                               fillcolor='#FFB74D',
                               color='#E65100',
                               shape='cylinder',
                               penwidth='2')
                    db_az1.node('redis_az1', 'ElastiCache\nRedis Node',
                               fillcolor='#FFB74D',
                               color='#E65100',
                               shape='cylinder',
                               penwidth='2')

            # === AVAILABILITY ZONE 2 ===
            with vpc.subgraph(name='cluster_az2') as az2:
                az2.attr(label='Availability Zone 2 (us-west-2b)',
                        fontsize='12',
                        style='solid',
                        color='#FF6F00',
                        penwidth='2')

                # Public Subnet with NAT Gateway at top
                with az2.subgraph(name='cluster_public_az2') as pub_az2:
                    pub_az2.attr(label='Public Subnet (10.X.1.0/24)',
                                fontsize='10',
                                style='filled',
                                fillcolor='#E8F4F8',
                                color='#1E88E5')
                    pub_az2.node('nat_az2', 'NAT Gateway\n(Elastic IP)',
                                fillcolor='#90CAF9',
                                color='#1565C0')
                    pub_az2.node('alb_az2', 'Application Load Balancer\n(Spans AZs)',
                                fillcolor='#64B5F6',
                                color='#1565C0',
                                shape='box3d',
                                style='rounded,filled,dashed',)

                # Private Subnet AZ2
                with az2.subgraph(name='cluster_private_az2') as priv_az2:
                    priv_az2.attr(label='Private Subnet (10.X.11.0/24)',
                                 fontsize='10',
                                 style='filled',
                                 fillcolor='#F3E5F5',
                                 color='#8E24AA')
                    priv_az2.node('ecs_task_az2', 'ECS Tasks\n(Drupal Containers)',
                                 fillcolor='#CE93D8',
                                 color='#6A1B9A',
                                 shape='component',
                                 penwidth='2')

                # Database Subnet AZ2
                with az2.subgraph(name='cluster_db_az2') as db_az2:
                    db_az2.attr(label='Database Subnet (10.X.21.0/24)',
                               fontsize='10',
                               style='filled',
                               fillcolor='#FFF3E0',
                               color='#F57C00')
                    db_az2.node('rds_az2', 'RDS MySQL\n(Standby)',
                               fillcolor='#FFB74D',
                               color='#E65100',
                               shape='cylinder',
                               style='rounded,filled,dashed')
                    db_az2.node('redis_az2', 'ElastiCache\n(Spans AZs)',
                               fillcolor='#FFB74D',
                               color='#E65100',
                               shape='cylinder',
                               style='rounded,filled,dashed')


    # === FORCE VERTICAL ORDERING ===
    # Main vertical flow: Internet -> WAF -> IGW -> ALB
    with dot.subgraph() as s:
        s.attr(rank='same')
        s.node('internet')

    with dot.subgraph() as s:
        s.attr(rank='same')
        s.node('waf')

    with dot.subgraph() as s:
        s.node('igw')

    with dot.subgraph() as s:
        s.attr(rank='same')
        s.node('alb_az1')
        s.node('alb_az2')

    with dot.subgraph() as s:
        s.attr(rank='same')
        s.node('nat_az1')
        s.node('nat_az2')

    with dot.subgraph() as s:
        s.attr(rank='same')
        s.node('ecs_task_az1')
        s.node('ecs_task_az2')

    with dot.subgraph() as s:
        s.attr(rank='same')
        s.node('redis_az1')
        s.node('redis_az2')

    with dot.subgraph() as s:
        s.attr(rank='same')
        s.node('rds_az1')
        s.node('rds_az2')

    # # Add invisible edges within each AZ to force vertical ordering
    dot.edge('alb_az1', 'nat_az1', style='invis')
    dot.edge('alb_az2', 'nat_az2', style='invis')
    dot.edge('redis_az1', 'rds_az1', style='invis')
    dot.edge('redis_az2', 'rds_az2', style='invis')

    # === PRIMARY TRAFFIC FLOW (Main Request Path) ===
    # Internet -> WAF -> IGW -> ALB
    dot.edge('internet', 'waf', color='#1976D2', style='bold', penwidth='3')
    dot.edge('waf', 'igw', color='#1976D2', penwidth='3')
    dot.edge('igw', 'alb_az1', color='#1E88E5', penwidth='2.5')
    dot.edge('igw', 'alb_az2', color='#1E88E5', penwidth='2.5')
    # ALB -> ECS Tasks (Load balanced)
    dot.edge('alb_az1', 'ecs_task_az1', color='#8E24AA', penwidth='2.5')
    dot.edge('alb_az2', 'ecs_task_az2', color='#8E24AA', penwidth='2.5')

    # ECS Tasks -> Backend Services
    dot.edge('ecs_task_az1', 'rds_az1', color='#F57C00', penwidth='2')
    dot.edge('ecs_task_az1', 'redis_az1', color='#F57C00', penwidth='2')
    dot.edge('ecs_task_az2', 'rds_az1', color='#F57C00', penwidth='2')
    dot.edge('ecs_task_az2', 'redis_az2', color='#F57C00', penwidth='2')

    # === OUTBOUND TRAFFIC (From ECS to Internet) ===
    dot.edge('ecs_task_az1', 'nat_az1', label='outbound', color='#7B1FA2', style='dotted', penwidth='1.5', fontsize='9')
    dot.edge('ecs_task_az2', 'nat_az2', label='outbound', color='#7B1FA2', style='dotted', penwidth='1.5', fontsize='9')
    dot.edge('nat_az1', 'igw', color='#1E88E5', style='dotted', penwidth='1.5')
    dot.edge('nat_az2', 'igw', color='#1E88E5', style='dotted', penwidth='1.5')

    # === HIGH AVAILABILITY ===
    # RDS Multi-AZ Replication
    dot.edge('redis_az1', 'redis_az2', label='same node', color='#EF6C00', style='dashed', dir='both', penwidth='2', fontsize='9')
    dot.edge('rds_az1', 'rds_az2', label='synchronous replication', color='#EF6C00', style='dashed', dir='both', penwidth='2', fontsize='9')

    return dot

if __name__ == '__main__':
    # Generate the diagram
    diagram = create_aws_infrastructure_diagram()

    # Render to file
    output_path = diagram.render('aws_drupal_infrastructure', cleanup=True)
    print(f"✓ Diagram generated: {output_path}")
    print("✓ Infrastructure visualization complete!")
