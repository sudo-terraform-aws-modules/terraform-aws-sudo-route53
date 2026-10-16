locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : var.zone_id

  records_map = {
    for r in var.records : "${upper(r.type)}-${r.name}" => r
  }
}

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name          = var.zone_name
  comment       = var.comment
  force_destroy = var.force_destroy

  dynamic "vpc" {
    for_each = var.private_zone ? var.vpc_associations : []
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = lookup(vpc.value, "vpc_region", null)
    }
  }

  tags = var.tags
}

resource "aws_route53_record" "ns" {
  count = var.create_zone && !var.private_zone ? 1 : 0

  allow_overwrite = true
  zone_id         = aws_route53_zone.this[0].zone_id
  name            = var.zone_name
  type            = "NS"
  ttl             = "172800"
  records         = aws_route53_zone.this[0].name_servers
}

resource "aws_route53_record" "this" {
  for_each = local.records_map

  zone_id         = local.zone_id
  name            = each.value.name == "@" ? var.zone_name : each.value.name
  type            = upper(each.value.type)
  allow_overwrite = true

  # ttl and records are null for alias records
  ttl     = try(each.value.alias, null) != null ? null : try(each.value.ttl, var.default_ttl)
  records = try(each.value.alias, null) != null ? null : try(each.value.values, [])

  dynamic "alias" {
    for_each = try(each.value.alias, null) != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = try(alias.value.evaluate_target_health, false)
    }
  }
}
