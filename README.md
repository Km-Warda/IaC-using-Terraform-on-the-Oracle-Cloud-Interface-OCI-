This project is a simple IaC application, creating a simple instance on the Oracle Cloud Infrastructure (OCI), in a public subnet with simple controlled access.

It applies:

1. **Virtual Cloud Network (VCN):** 
   - A VCN is a logically isolated network within OCI.
2. **Subnets:**
   - One subnet.
3. **Internet Gateway:**
   - One internet gateway.
4. **Route Table:**
   - One routing table with a public access route.
5. **Security Lists:**
   - Set up security lists to control ingress and egress traffic in the public subnet.
6. **Key Pair:**
   - Create an SSH key pair, to be used to authenticate and access the Oracle Compute instance.
7. **Compute Instance:**
   - Launch an Oracle Compute instance in the public subnet.
8. **Storage:**
   - Storage Volume.
9. **Security Groups:**
   - Configuring security groups to control traffic to and from the instance.


# Provider.tf
It defines the version & the source required for initializing the terraform backend. Here we stated the region in which our resources will be deployed, & the required authorization for creating resources.
```
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
```
# Services
## VCN
The official OCI module for the VCN was used, which sets & creates:
- VCN
- Internet Gateway
- VCN CIDR Blocks
- Subnets
- Internet Gateway route rules

```
module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
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
```

The `output.tf` file has the outputs of the module:
```
output "internet_gateway_id" {
  value = module.vcn.internet_gateway_id
}
output "subnet_ids" {
  value = module.vcn.subnet_ids
}
output "vcn_id" {
  value = module.vcn.vcn_id
}
output "ig_route_id" {
  value = module.vcn.ig_route_id
}
```

The required parameters for this module is defined in the `variables.tf` file
```
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
  type = list(object({
    destination = string
    network_id  = string
  }))
  default = [
    {
      destination = "0.0.0.0/0"
      network_id  = module.vcn.internet_gateway_id
    }
  ]
}
```

## Security Lists & Security Groups
The main difference between the security lists & the security groups, is that the security lists are for controlling egress & ingress access **on the subnet level**, while the security groups are for controlling egress & ingress access **on the instance level**.

The code is in `main.tf`, it allows SSH for the device that would be specified & passed to the `ssh_client_ip` variable, as well as allowing all outbound connections & inbound connection for the port `3000`, all the port ranges & protocol types can be updated through variables in the `variables.tf` file.
```
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
      source      = var.ssh_client_ip
      protocol    = "tcp"
      tcp_options {
        max = 22
        min = 22
      }
    }
}

#security group
resource "oci_core_security_group" "instance_security_group" {
  compartment_id = var.mycompartment_id
  vcn_id         = module.vcn.vcn_id
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
      source      = var.ssh_client_ip
      protocol    = "tcp"
      tcp_options {
        max = 22
        min = 22
      }
    }
}
```

## Compute Instance
This is the instance which the application would be stored on, its size can be chosen through updating the value of the `instance_shape` variable.
Also, the metadata value was set to define a public key that will be passed on later for accessing the instance.
```
#compute instance
resource "oci_core_instance" "compute_instance" {
    availability_domain = values(var.subnet_cidr_block)[0].availability_domain
    compartment_id = var.mycompartment_id
    shape = var.instance_shape
    metadata = {
      ssh_authorized_keys = oci_identity_ssh_key.instance_ssh_key.ssh_public_key
  }
}
```

## Storage
This is additional storage volume to be attached to the instance. To attach it, it's required to create another resource called volume attachment resource.

- This is the code for creating the storage volume, its size can be changed through the variable `volume_size`
```
#storage
resource "oci_core_volume" "block_volume" {
  availability_domain = values(var.subnet_cidr_block)[0].availability_domain
  compartment_id     = var.mycompartment_id
  display_name        = "block-volume"
  size_in_gbs         = var.volume_size
}
```
- This  is the volume attachment resource, it uses the id output after creating the instance & the volume together.
```
#Attaching the storage to the instance
resource "oci_core_volume_attachment" "volume_attachment_to_instance" {
  instance_id        = oci_core_instance.compute_instance.id
  volume_id          = oci_core_volume.block_volume.id
  display_name       = "volume-attachment-to-instance"
  is_read_only       = false
}
```
The `output.tf` file has the outputs of these resources:
```
#Instance outputs
output "instance_id" {
  value = oci_core_instance.compute_instance.id
}
output "instance_public_ip" {
  value = oci_core_instance.compute_instance.public_ip
}
output "instance_private_ip" {
  value = oci_core_instance.compute_instance.private_ip
}
#Storage outputs
output "block_volume_id" {
  value       = oci_core_volume.block_volume.id
}
output "block_volume_display_name" {
  value       = oci_core_volume.block_volume.display_name
}
output "block_volume_size" {
  value       = oci_core_volume.block_volume.size_in_gbs
}
```

## Key Pair
For accessing the instance, we allowed the SSH port for the connection, but we need a key pair that we defined in the instance metadata before, we will have the privat4e key locally, & define the public key on the instance.
Here is how the public key is defined
```
#SSH key pair
resource "oci_identity_ssh_key" "instance_ssh_key" {
  compartment_id = var.mycompartment_id
  display_name   = "ssh-key"
  key            = file(var.ssh_public_key_path)
}
```

# Backend.tf
For storing the terraform state file remotely 'AWS S3 is used here', so that errors can be avoided if multiple interactions were made by different code moderators, as it must stay the same for everyone.
The state file is created on an OCI block storage bucket.
**Instructions:**

1. **Create an S3 Bucket:**
   - Log in to the [AWS Management Console](https://aws.amazon.com/console/).
   - Navigate to the S3 service.
   - Create a new bucket, ensuring it has a globally unique name.

2. **Define S3 Bucket Details in `backend.tf`:**
   - Replace `"terraform-state-bucket-unique-name-karim"` with the unique name of the S3 bucket you created.
   - Choose a unique name for the bucket to avoid conflicts with other users or teams.

3. **Set AWS Region:**
   - Replace the `region` with your preferred AWS region (e.g., `"us-east-1"` is used).

4. **Enable Server-Side Encryption:**
   - Set `encrypt` to `true` if you want to enable server-side encryption for the Terraform state file

And this is the code of the `backend.tf` file itself.
```
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-unique-name-karim"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
```
# Terraform.tfvars
*NOTE:* The variables might need some updates from time to time, thus they are defined also in the `terraform.tfvars` file, which upon updated, will be taken as the value of the keys instead of the one in the `variables.tf` file.
```
region = "us-ashburn-1"
mycompartment_id = "<Account ID>"
egress_destination = "0.0.0.0/0"
egress_protocol = "tcp"
egress_max_destination_port = "65535"
egress_min_destination_port = "1"
ingress_destination = "10.0.0.0/16"
ingress_protocol = "tcp"
ingress_max_destination_port = "3000"
ingress_min_destination_port = "3000"
instance_shape = "VM.Standard2.1"
volume_size = 50
ssh_public_key_path = "~/.ssh/sshkeey.pub"
ssh_client_ip= "156.197.32.210"
```