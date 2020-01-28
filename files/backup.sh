#!/bin/sh
docker-compose down
tar Jcv /opt/mastodon/ | /opt/google-cloud-sdk/bin/gsutil cp -s coldline - gs://${GCS_BUCKET}/backup/$(date "+%Y-%m-%d-%H-%M-%S").tar.xz
docker-compose up -d
