output "app_instance_ips" {
  value = google_compute_instance.reddit_app[*].network_interface[0].access_config[0].nat_ip
}
