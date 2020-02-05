#!/bin/sh
terraform output --json | jq '{mastodon:[.ip_addr.value],_meta:{hostvars:{(.ip_addr.value):{gcs_bucket:.bucket.value}}}}'
