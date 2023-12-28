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