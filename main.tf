#OCI Official VCN module was used
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


#Security list
resource "oci_core_security_list" "subnet_security_list" {
    compartment_id = var.mycompartment_id
    vcn_id = module.vcn.vcn_id
    egress_security_rules {
      destination = var.egress_destination
      protocol = var.egress_protocol
      tcp_options {
        max = var.egress_max_destination_port
        min = var.egress_min_destination_port
        source_port_range {
          max = var.egress_max_source_port
          min = var.egress_min_source_port
        }
      }
    }
    ingress_security_rules {
      source = var.ingress_destination
      protocol = var.ingress_protocol
      tcp_options {
        max = var.ingress_max_destination_port
        min = var.ingress_min_destination_port
        source_port_range {
          max = var.ingress_max_source_port
          min = var.ingress_min_source_port
        }
      }
    }
    #Allowing SSH (port 22)
    ingress_security_rules {
      source      = var.ssh_client_ip
      protocol    = "tcp"
      tcp_options {
        max = 22
        min = 22
      }
    }
}

#security group
resource "oci_core_security_group" "instance_security_group" {
  compartment_id = var.mycompartment_id
  vcn_id         = module.vcn.vcn_id

    egress_security_rules {
      destination = var.egress_destination
      protocol = var.egress_protocol
      tcp_options {
        max = var.egress_max_destination_port
        min = var.egress_min_destination_port
        source_port_range {
          max = var.egress_max_source_port
          min = var.egress_min_source_port
        }
      }
    }
    ingress_security_rules {
      source = var.ingress_destination
      protocol = var.ingress_protocol
      tcp_options {
        max = var.ingress_max_destination_port
        min = var.ingress_min_destination_port
        source_port_range {
          max = var.ingress_max_source_port
          min = var.ingress_min_source_port
        }
      }
    }
    #Allowing SSH (port 22)
    ingress_security_rules {
      source      = var.ssh_client_ip
      protocol    = "tcp"
      tcp_options {
        max = 22
        min = 22
      }
    }
}


#compute instance
resource "oci_core_instance" "compute_instance" {
    availability_domain = values(var.subnet_cidr_block)[0].availability_domain
    compartment_id = var.mycompartment_id
    shape = var.instance_shape
    metadata = {
      ssh_authorized_keys = oci_identity_ssh_key.instance_ssh_key.ssh_public_key
  }
}

#storage
resource "oci_core_volume" "block_volume" {
  availability_domain = values(var.subnet_cidr_block)[0].availability_domain
  compartment_id     = var.mycompartment_id
  display_name        = "block-volume"
  size_in_gbs         = var.volume_size
}

#Attaching the storage to the instance
resource "oci_core_volume_attachment" "volume_attachment_to_instance" {
  instance_id        = oci_core_instance.compute_instance.id
  volume_id          = oci_core_volume.block_volume.id
  display_name       = "volume-attachment-to-instance"
  is_read_only       = false
}

#SSH key pair 
resource "oci_identity_ssh_key" "instance_ssh_key" {
  compartment_id = var.mycompartment_id
  display_name   = "ssh-key"
  key            = file(var.ssh_public_key_path)
}
