#OCI Official VCN module was used
module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.6.0"
  compartment_id = var.mycompartment_id 
  vcn_name = "primary_vcn"
  defined_tags = "operations"
  region = var.region
  vcn_cidrs = var.vcn_cidr_block
  subnets = var.subnet_cidr_block
}


#Internet Gateway
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
}
#Route Table
resource "oci_core_route_table" "route_table" {
  compartment_id = var.mycompartment_id
  vcn_id         = module.vcn.vcn_id
  route_rules    = var.routes
}
#Route table association to the first subnet
resource "oci_core_subnet_route_table_association" "association" {
  subnet_id      = module.vcn.subnet_ids[0]
  route_table_id = oci_core_route_table.route_table.id
}


#Security list
resource "oci_core_security_list" "subnet_security_list" {
  compartment_id = var.mycompartment_id
  vcn_id         = module.vcn.vcn_id
  egress_security_rules {
    destination = var.egress_rules["destination"]
    protocol    = var.egress_rules["protocol"]

    tcp_options {
      max = var.egress_rules["tcp_options"]["max"]
      min = var.egress_rules["tcp_options"]["min"]

      source_port_range {
        max = var.egress_rules["tcp_options"]["source_port_range"]["max"]
        min = var.egress_rules["tcp_options"]["source_port_range"]["min"]
      }
    }
  }
  ingress_security_rules {
    source    = var.ingress_rules["source"]
    protocol  = var.ingress_rules["protocol"]

    tcp_options {
      max = var.ingress_rules["tcp_options"]["max"]
      min = var.ingress_rules["tcp_options"]["min"]

      source_port_range {
        max = var.ingress_rules["tcp_options"]["source_port_range"]["max"]
        min = var.ingress_rules["tcp_options"]["source_port_range"]["min"]
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
    destination = var.egress_rules["destination"]
    protocol    = var.egress_rules["protocol"]

    tcp_options {
      max = var.egress_rules["tcp_options"]["max"]
      min = var.egress_rules["tcp_options"]["min"]

      source_port_range {
        max = var.egress_rules["tcp_options"]["source_port_range"]["max"]
        min = var.egress_rules["tcp_options"]["source_port_range"]["min"]
      }
    }
  }
  ingress_security_rules {
    source    = var.ingress_rules["source"]
    protocol  = var.ingress_rules["protocol"]

    tcp_options {
      max = var.ingress_rules["tcp_options"]["max"]
      min = var.ingress_rules["tcp_options"]["min"]

      source_port_range {
        max = var.ingress_rules["tcp_options"]["source_port_range"]["max"]
        min = var.ingress_rules["tcp_options"]["source_port_range"]["min"]
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