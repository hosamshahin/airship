module "fargate_service" {
  source  = "blinkist/airship-ecs-service/aws"
  version = "0.9.2"

  name = "nginx"

  ecs_cluster_id = "${module.ecs.cluster_id}"

  region = "us-east-1"

  fargate_enabled = true

  awsvpc_enabled            = true
  awsvpc_subnets            = ["${module.vpc.private_subnets}"]
  awsvpc_security_group_ids = ["${aws_security_group.ecs_service_sg.id}"]

  load_balancing_type = "application"

  # The ARN of the ALB, when left-out the service, 
  load_balancing_properties_lb_arn = "${module.alb_shared_services_external.load_balancer_id}"

  # http listener ARN
  load_balancing_properties_lb_listener_arn = "${element(module.alb_shared_services_external.http_tcp_listener_arns,0)}"

  # The VPC_ID the target_group is being created in
  load_balancing_properties_lb_vpc_id = "${module.vpc.vpc_id}"

  # load_balancing_properties_route53_record_type = "NONE"
  # The route53 zone for which we create a subdomain
  load_balancing_properties_route53_zone_id = "${data.aws_route53_zone.zone.zone_id}"

  # health_uri defines which health-check uri the target 
  # group needs to check on for health_check, defaults to /ping
  load_balancing_properties_health_uri = "/"

  load_balancing_properties_https_enabled = false

  container_cpu             = 256
  container_memory          = 512
  container_port            = 80
  bootstrap_container_image = "nginx:stable"

  # force_bootstrap_container_image to true will 
  # force the deployment to use var.bootstrap_container_image as container_image
  # if container_image is already deployed, no actual service update will happen
  # force_bootstrap_container_image = false

  # Initial ENV Variables for the ECS Task definition
  container_envvars {
    ENV_VARIABLE = "SOMETHING"
  }
  # capacity_properties defines the size in task for the ECS Service.
  # Without scaling enabled, desired_capacity is the only necessary property
  # defaults to 2
  # With scaling enabled, desired_min_capacity and desired_max_capacity 
  # define the lower and upper boundary in task size
  capacity_properties_desired_capacity = "2"
}
