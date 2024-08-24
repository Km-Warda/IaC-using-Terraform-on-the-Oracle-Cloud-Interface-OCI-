variable "region" {  
  default     = "us-ashburn-1"
}
variable "mycompartment_id" {
  default = "<Account ID>"
}

variable  "vcn_cidr_block" {
  default = ["10.0.0.0/16"]
}
variable "subnet_cidr_block" {
  default = [
    {
      subnet1 = {
        cidr_block          = "10.0.0.0/24"
        display_name        = "subnet1"
        availability_domain = "AD-1"
      }
    }
  ]
}


variable "routes" {
  type = map(object({
    network_entity_id = string
    cidr_block  = string
    destination = string
    destination_type = string
  }))
  default = {
    route1 = {
      network_entity_id   = oci_core_internet_gateway.internet_gateway.id
      cidr_block          = "10.0.0.0/24"
      destination         = "10.0.0.0/24"
      destination_type    = "CIDR"
    }
    #We can add more
}
}


variable "egress_rules" {
  type = map(object({
    destination = string
    protocol    = string
    tcp_options = object({
      max               = string
      min               = string
      source_port_range = object({
        max = string
        min = string
      })
    })
  }))

  default = {
    destination = "0.0.0.0/0"
    protocol    = "tcp"
    tcp_options = {
      max = "65535"
      min = "1"
      source_port_range = {
        max = "65535"
        min = "1"
      }
    }
  }
}

variable "ingress_rules" {
  type = map(object({
    source      = string
    protocol    = string
    tcp_options = object({
      max               = string
      min               = string
      source_port_range = object({
        max = string
        min = string
      })
    })
  }))

  default = {
    source    = "10.0.0.0/16"
    protocol  = "tcp"
    tcp_options = {
      max = "3000"
      min = "3000"
      source_port_range = {
        max = "65535"
        min = "1"
      }
    }
  }
}

variable "instance_shape" {
  type    = string
  default = "VM.Standard2.1"
}


variable "volume_size" {
  type = number
  default = 50   #in GB
}


variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/sshkey.pub"  # public SSH key path
}
#The IP address of the SSH client
variable "ssh_client_ip" {
  type    = string
  default = "156.197.32.210"  #example
}
