module "ecs" {
  source  = "blinkist/airship-ecs-cluster/aws"
  version = "0.5.1"

  name = "ecs-demo"

  # create_roles defines if we create IAM Roles for EC2 instances
  create_roles = false

  # create_autoscalinggroup defines if we create an ASG for ECS
  create_autoscalinggroup = false
}