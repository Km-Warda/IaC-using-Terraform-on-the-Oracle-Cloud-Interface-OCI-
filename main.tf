#OCI VCN module was used

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
}

#storage
resource "oci_core_volume" "block_volume" {
  availability_domain = values(var.subnet_cidr_block)[0].availability_domain
  compartment_id     = var.mycompartment_id
  display_name        = "block-volume"
  size_in_gbs         = var.volume_size
}

#SSH key pair 
resource "oci_identity_ssh_key" "instance_ssh_key" {
  compartment_id = var.mycompartment_id
  display_name   = "ssh-key"
  key            = file(var.ssh_public_key_path)
}




#Block storage for remote tfstate file
resource "oci_objectstorage_bucket" "tfstate_bucket" {
    compartment_id = var.mycompartment_id
    name = "tfstate_bucket"
    namespace = "remote_tfstate_file"
}