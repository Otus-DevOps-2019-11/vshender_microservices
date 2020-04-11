variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable environment {
  description = "Gitlab environment name"
}

variable username {
  description = "User name to create on the env instance"
  default     = "user"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
  default     = "/.id_rsa"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
  default     = "/.id_rsa.pub"
}

variable disk_image {
  description = "Disk image for the env instance"
  default     = "ubuntu-1804-lts"
}

variable disk_size {
  description = "Disk size for the env instance"
  default     = "10"
}
