locals {
  project = "kouzoh-p-kaz"
  region  = "asia-northeast1"
  name    = "mastodon"
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

###########################
##### service account #####
###########################

resource "google_service_account" "sa" {
  account_id   = local.name
  display_name = "Mastodon service account"
}

resource "google_compute_instance_iam_binding" "instance_iam_binding" {
  zone          = google_compute_instance.instance.zone
  instance_name = google_compute_instance.instance.name
  role          = "roles/compute.instanceAdmin"

  members = [
    "serviceAccount:${google_service_account.sa.email}",
  ]
}

resource "google_pubsub_topic_iam_binding" "topic_iam_binding" {
  topic = google_pubsub_topic.topic.name
  role  = "roles/pubsub.publisher"

  members = [
    "serviceAccount:${google_service_account.sa.email}",
  ]
}

#############################
##### mastodon instance #####
#############################

output "ip_addr" {
  value = google_compute_address.ip.address
}

data "google_compute_network" "network" {
  name = "default"
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

resource "google_compute_address" "ip" {
  name   = local.name
  region = local.region
}

resource "google_compute_instance" "instance" {
  name         = local.name
  machine_type = "g1-small"
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
      size  = 16
      image = "projects/arch-linux-gce/global/images/family/arch"
    }
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  service_account {
    email  = google_service_account.sa.email
    scopes = ["pubsub"]
  }

  metadata = {
    shutdown-script = <<EOS
#!/bin/sh
/opt/google-cloud-sdk/bin/gcloud pubsub topics publish ${google_pubsub_topic.topic.id} --message " "
EOS
  }
}

#######################
##### re-launcher #####
#######################

resource "google_pubsub_topic" "topic" {
  name = local.name
}

resource "google_storage_bucket" "bucket" {
  name     = "${local.project}-${local.name}"
  location = local.region
}

resource "google_storage_bucket_object" "archive" {
  name   = "${filemd5("archive.zip")}.zip"
  bucket = google_storage_bucket.bucket.name
  source = "archive.zip"
}

resource "google_cloudfunctions_function" "function" {
  name = local.name

  runtime             = "nodejs10"
  available_memory_mb = 128
  entry_point         = "run"
  timeout             = 300

  service_account_email = google_service_account.sa.email
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name

  environment_variables = {
    ZONE = google_compute_instance.instance.zone
    VM   = google_compute_instance.instance.name
  }

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = google_pubsub_topic.topic.id
  }
}
