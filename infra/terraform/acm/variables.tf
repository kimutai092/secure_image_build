variable "region"         { type = string }
variable "domain_name"    { type = string }
variable "hosted_zone_id" { type = string }
variable "san_domains"    { type = list(string) default = [] }
