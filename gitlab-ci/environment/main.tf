terraform {
  required_version = "0.12.24"
}

provider "google" {
  version = "~>2.20"

  credentials = "service-account.json"
  project     = var.project
  region      = var.region
}

resource "google_compute_instance" "env_instance" {
  name         = var.environment
  machine_type = "g1-small"
  zone         = var.zone

  tags = ["reddit-app"]

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = var.disk_size
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.username}:${file(var.public_key_path)}"
  }

  connection {
    type        = "ssh"
    host        = self.network_interface[0].access_config[0].nat_ip
    user        = var.username
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y docker.io",
      "sudo apt update && sudo apt install -y docker-compose",
    ]
  }
}

resource "null_resource" "run_app" {
  connection {
    type        = "ssh"
    host        = google_compute_instance.env_instance.network_interface[0].access_config[0].nat_ip
    user        = var.username
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/${var.username}/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo docker-compose up -d"
    ]
  }
}
