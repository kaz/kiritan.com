.PHONY: plan
plan: .terraform archive.zip
	terraform plan

.PHONY: apply
apply: .terraform archive.zip
	terraform apply

.terraform:
	terraform init -backend-config="bucket=$(BUCKET)"

archive.zip: relaunch/index.js relaunch/package.json
	zip -j $@ $?

.PHONY: clean
clean:
	rm -rf .terraform archive.zip

ANSIBLE=ansible-playbook playbook.yaml -i hosts.sh

.PHONY: ansible-apply
ansible-apply: group_vars/mastodon.yaml
	$(ANSIBLE)

.PHONY: ansible-check
ansible-check: group_vars/mastodon.yaml
	$(ANSIBLE) --check --diff

.PHONY: encrypt
encrypt:
	gpg --default-recipient-self --encrypt env.mk
	gpg --default-recipient-self --encrypt group_vars/mastodon.yaml

env.mk group_vars/mastodon.yaml:
	gpg --output $@ --decrypt $@.gpg

include env.mk
