output "asg_name" {
  description = "Nom de l'Auto Scaling Group."
  value       = aws_autoscaling_group.web.name
}

output "launch_template_id" {
  description = "Identifiant du Launch Template."
  value       = aws_launch_template.web.id
}

output "launch_template_version" {
  description = "Dernière version du Launch Template."
  value       = aws_launch_template.web.latest_version
}

output "ami_id" {
  description = "AMI utilisée par les instances."
  value       = data.aws_ssm_parameter.ami.insecure_value
}
