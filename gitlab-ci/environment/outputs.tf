output "env_instance_ip" {
  value = google_compute_instance.env_instance.network_interface[0].access_config[0].nat_ip
}
