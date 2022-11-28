# Copyright (c) 2021 Microsoft
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Location of the environment, default is Switzerland Nord
variable "location" {
  default = "westeurope"
}

#Usecase prefix used in naming convention for uniqueness, default is ebspp
variable "prefix" {
  type = string
  default = "sow"
}


#Usecase prefix used in naming convention for uniqueness, default is ebspp
variable "usecase_name" {
  type = string
  default = "sow"
}


#Usecase postfix used in naming convention for uniqueness
resource "random_string" "postfix" {
  length = 6
  special = false
  upper = false
}


#Friendly name of the ML-workspace, default is aml-ebspp
variable "workspace_display_name" {
  default = "aml-sow"
}


variable ip_range {
  type = string
  default = "85.216.51.235" #INFOMOTION GP
}


#Insert your Subscription_id
variable "SUBSCRIPTION_ID" {
  type = string
  default = "..."
}

#Insert your Client_id
variable "SP_CLIENT_ID" {
  type = string
  default = "..."
}

#Insert Client_Secret
variable "SP_CLIENT_SECRET" {
  type = string
  default = "..."
}

#Insert Tenant_id
variable "SP_TENANT_ID" {
  type = string
  default = "..."
}

