.PHONY: plan
plan: .terraform archive.zip
	terraform plan

.PHONY: apply
apply: .terraform archive.zip
	terraform apply

.terraform:
	terraform init

archive.zip: relaunch/index.js relaunch/package.json
	zip -j $@ $?

.PHONY: clean
clean:
	rm -rf .terraform archive.zip

.PHONY: ansible
ansible:
	ansible-playbook -i hosts.sh --diff playbook.yaml
