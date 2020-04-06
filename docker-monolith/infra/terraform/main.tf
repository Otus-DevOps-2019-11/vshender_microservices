terraform {
  required_version = "~>0.12.19"
}

provider "google" {
  version = "~>2.20"

  project = var.project
  region  = var.region
}

resource "google_compute_instance" "reddit_app" {
  count = var.app_instance_count

  name         = "reddit-app-${count.index}"
  machine_type = "g1-small"
  zone         = var.zone

  tags = ["reddit-app"]

  boot_disk {
    initialize_params {
      image = var.app_disk_image
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
}

resource "google_compute_firewall" "firewall_reddit_app" {
  name = "allow-reddit-app"

  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["reddit-app"]
}
