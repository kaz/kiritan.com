#!/bin/sh
terraform output --json | jq '{mastodon:[.ip_addr.value]}'
