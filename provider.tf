terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "5.23.0"
    }
  }
}

provider "oci" {
   auth = "ResourcePrincipal"
   region = var.region
}
