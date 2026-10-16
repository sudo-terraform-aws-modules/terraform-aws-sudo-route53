variable "create_zone" {
  type        = bool
  description = "Set to true to create a new Route53 hosted zone. Set to false to manage records in an existing zone."
  default     = true
}

variable "zone_id" {
  type        = string
  description = "ID of an existing hosted zone. Required when create_zone is false."
  default     = ""

  validation {
    condition     = !(!var.create_zone && var.zone_id == "")
    error_message = "zone_id must be provided when create_zone is false."
  }
}

variable "zone_name" {
  type        = string
  description = "Name of the hosted zone (your domain name)."
}

variable "private_zone" {
  type        = bool
  description = "Set to true to create a private hosted zone. Requires vpc_associations."
  default     = false
}

variable "vpc_associations" {
  type = list(object({
    vpc_id     = string
    vpc_region = optional(string)
  }))
  description = "List of VPCs to associate with a private hosted zone."
  default     = []
}

variable "comment" {
  type        = string
  description = "Comment for the hosted zone."
  default     = "Managed by Terraform"
}

variable "force_destroy" {
  type        = bool
  description = "If true, all records in the zone will be deleted on destroy."
  default     = false
}

variable "default_ttl" {
  type        = number
  description = "Default TTL for records that do not specify one."
  default     = 300
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the hosted zone."
  default     = {}
}

variable "records" {
  type = list(object({
    name   = string
    type   = string
    ttl    = optional(number)
    values = optional(list(string), [])
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, false)
    }))
  }))
  description = <<-EOT
    Unified list of DNS records. Supports both regular and alias records.
    Use "@" as name for apex records.

    For static records, define inline or load from a YAML file:
      records = yamldecode(file("records.yaml"))

    For dynamic AWS resource references, use concat():
      records = concat(
        yamldecode(file("records.yaml")),
        [
          {
            name  = "app"
            type  = "A"
            alias = {
              name                   = aws_lb.this.dns_name
              zone_id                = aws_lb.this.zone_id
              evaluate_target_health = true
            }
          }
        ]
      )
  EOT
  default = []
}
