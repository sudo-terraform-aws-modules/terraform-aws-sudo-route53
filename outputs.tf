output "zone_id" {
  description = "Hosted zone ID."
  value       = local.zone_id
}

output "zone_name" {
  description = "Name of the hosted zone."
  value       = var.zone_name
}

output "name_servers" {
  description = "Name servers for the hosted zone. Only populated when create_zone is true."
  value       = try(aws_route53_zone.this[0].name_servers, [])
}

output "private_zone" {
  description = "Whether this is a private hosted zone."
  value       = var.private_zone
}
