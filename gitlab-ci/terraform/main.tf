terraform {
  required_version = "~>0.12.19"
}

provider "google" {
  version = "~>2.20"

  project = var.project
  region  = var.region
}

resource "google_compute_instance" "gitlab" {
  name         = "gitlab"
  machine_type = "n1-standard-1"
  zone         = var.zone

  tags = ["gitlab"]

  boot_disk {
    initialize_params {
      image = var.gitlab_disk_image
      size  = var.gitlab_disk_size
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "gitlab:${file(var.public_key_path)}"
  }
}

resource "google_compute_firewall" "firewall_gitlab" {
  name = "allow-gitlab"

  network = "default"

  allow {
    protocol = "tcp"
    ports    = [80, 443]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["gitlab"]
}
