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

resource "google_compute_address" "ip" {
  name = local.name
}

resource "google_compute_instance" "instance" {
  name         = local.name
  machine_type = "n1-standard-1"
  zone         = "${local.region}-b"

  tags = ["http-server"]

  network_interface {
    network = "default"
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
