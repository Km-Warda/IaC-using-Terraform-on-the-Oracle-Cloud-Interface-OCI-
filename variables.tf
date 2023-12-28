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
  { subnet1 = {
      cidr_block     = "10.0.0.0/24"
      display_name   = "subnet1"
      availability_domain = "AD-1"
    }
  }
}


variable "routes" {
  type = list(object({
    destination = string
    network_id  = string
  }))
  default = [
    {
      destination = "0.0.0.0/0"
      network_id  = module.vcn.internet_gateway_id
      
    },
  ]
}


variable "egress_destination" {
  type    = string
  default = "0.0.0.0/0" #all outbound is permited
}
variable "egress_protocol" {
  type    = string
  default = "tcp"
}
variable "egress_max_destination_port" {
  type = string
  default = "65535"
}
variable "egress_min_destination_port" {
  type = string
  default = "1"
}

variable "ingress_destination" {
  type    = string
  default = "10.0.0.0/16"  #all services in my vcn
}
variable "ingress_protocol" {
  type    = string
  default = "tcp"
}
variable "ingress_max_destination_port" {
  type = string
  default = "3000"
}
variable "ingress_min_destination_port" {
  type = string
  default = "3000"
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
  default = "~/.ssh/sshkeey.pub"  # public SSH key path
}
#The IP address of the SSH client
variable "ssh_client_ip" {
  type: string
  default = "156.197.32.210"  #example
}