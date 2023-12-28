module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.6.0"
  compartment_id = var.mycompartment_id 
  create_internet_gateway = true
  vcn_name = "primary_vcn"
  defined_tags = "operations"
  region = var.region
  vcn_cidrs = var.vcn_cidr_block
  subnets = var.subnet_cidr_block
  internet_gateway_route_rules = var.routes
}