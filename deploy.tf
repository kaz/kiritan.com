locals {
  name    = "mastodon"
  region  = "asia-northeast1"
  project = "kouzoh-p-kaz"
}

terraform {
  backend "gcs" {
    bucket = "kouzoh-p-kaz-tfstate"
    prefix = "mastodon"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

output "ip_addr" {
  value = google_compute_address.ip.address
}

data "google_compute_network" "network" {
  name = "default"
}

resource "google_compute_address" "ip" {
  name = local.name
}

resource "google_compute_firewall" "firewall" {
  name    = local.name
  network = data.google_compute_network.network.name

  target_tags = [local.name]

  source_ranges = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/12",
    "172.64.0.0/13",
    "131.0.72.0/22",
  ]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_instance" "instance" {
  name         = local.name
  machine_type = "n1-standard-1"
  zone         = "${local.region}-b"

  tags = [local.name]

  network_interface {
    network = data.google_compute_network.network.name
    access_config {
      nat_ip = google_compute_address.ip.address
    }
  }

  boot_disk {
    initialize_params {
      size  = 32
      image = "projects/arch-linux-gce/global/images/family/arch"
    }
  }

  scheduling {
    preemptible = false
  }
}
