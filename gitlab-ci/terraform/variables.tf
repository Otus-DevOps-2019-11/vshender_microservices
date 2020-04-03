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

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable gitlab_disk_image {
  description = "Disk image for gitlab"
}

variable gitlab_disk_size {
  description = "Disk size for gitlab"
  default     = 50
}
