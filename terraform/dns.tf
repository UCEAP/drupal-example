# Data source to reference wildcard certificate from common infrastructure
data "terraform_remote_state" "common_infra" {
  backend = "remote"

  config = {
    organization = "UCEAP"
    workspaces = {
      name = "common-infra-production"
    }
  }
}

# Route 53 A record for demo.drupal-example.uceap.net pointing to ALB
resource "aws_route53_record" "app" {
  zone_id = data.terraform_remote_state.common_infra.outputs.uceap_net_zone_id
  name    = "demo.drupal-example.uceap.net"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
