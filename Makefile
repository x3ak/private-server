.DEFAULT: help
.SILENT:
SHELL=bash

# internal & technical vars
RESERVED_PLAYBOOK=vagrantDummyBootstrap
CURRENT_TIME=$(shell date +"%Y-%m-%d/%H:%M")

# business vars
# escape special characters
INTERNAL_VM_NAME_NOT_ESCAPED=ansible-builder_${PLAYBOOK}
INTERNAL_VM_NAME=$(shell sed 's/\//_/g' <<< ${INTERNAL_VM_NAME_NOT_ESCAPED})

# customer parameters
HOSTNAME=$(shell hostname)

help: ## Display usage
	printf "\033[96mPiteur legacy server management\033[0m\n\n"
	grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

are-requirements-ok: ## Are the needed tools installed ?
	which docker >/dev/null 2>&1 || { echo >&2 "'docker' is required.\nPlease install it."; exit 1; }
	which ansible >/dev/null 2>&1 || { echo >&2 "'ansible' is required.\nPlease install it."; exit 1; }
	which ansible-galaxy >/dev/null 2>&1 || { echo >&2 "'ansible-galaxy' is required.\nPlease install it."; exit 1; }
	which vagrant >/dev/null 2>&1 || { echo >&2 "'vagrant' is required.\nPlease install it."; exit 1; }

is-vault-valid: ## Is the vault path is valid ?
ifndef VAULT
	echo "No 'VAULT' specified."
	echo "Aborting."
	exit 1
endif

	if [ ! -f "${VAULT}" ]; then \
		echo "Vault path '${VAULT}' does not exist"; \
		echo "Aborting"; \
		exit 1; \
	fi;

is-playbook-valid: ## Validate playbook path and name
ifndef PLAYBOOK
	echo "No 'PLAYBOOK' specified."
	echo "Please set it to a playbook located on the \`playbook\` folder."
	echo "Use as follow: \`make < command > PLAYBOOK=<playbook-name>\`"
	echo
	echo "Here are the available playbooks:"
	echo -e "\033[0;36m"
	cd ./playbook && ls -A1 */**.yml | cut -d "." -f 1 | sed 's/^/\t/'
	echo -e "\033[0m"
	echo "Aborting."
	exit 1
endif

# check for reserved name playbook
ifeq ($(PLAYBOOK), $(RESERVED_PLAYBOOK))
	echo -e "\033[0;31mThis playbook can't be used. Sorry…\033[0m"
	exit 1
endif

	if [ ! -f playbook/${PLAYBOOK}.yml ]; then \
		echo -e "\033[0;31mUnknown '${PLAYBOOK}' playbook.\033[0m"; \
		echo "Here are the available playbooks:"; \
		echo -e "\033[0;36m"; \
		cd ./playbook && ls -A1 */**.yml | cut -d "." -f 1 | sed 's/^/\t/'; \
		echo -e "\033[0m"; \
		echo "Aborting."; \
		exit 1; \
	fi;

##
# Dev targets
view-vault: are-requirements-ok is-vault-valid ## Decrypt & display a vault file. Usage: 'make view-vault VAULT=< vault-file-path >'
	echo -e "\033[0;36mContent of vault file '${VAULT}' is:\033[0m"
	ansible-vault decrypt --vault-password-file=secrets/vault_password --output=- ${VAULT}

run-ansible-galaxy: are-requirements-ok ## Run ansible-galaxy to download dependencies specified on 'requirements.yml' file
	echo -e "\033[0;36mRunning Ansible-galaxy to import roles (from 'requirements.yml' file)…\033[0m"
	ansible-galaxy install -r requirements.yml
	echo -e "\033[0;32m -> Don't forget to add the newly imported roles on the './roles/.gitignore' file.\033[0m"

create-role: ## Create a new role. Usage: `make create-role ROLE=< role-name >`
ifndef ROLE
	echo "Please provide a role name by using command \`make create-role ROLE=\"<role-name>\"\`"
	exit 1
endif
	if [ -d "roles/${ROLE}" ]; then echo "role \"${ROLE}\" already exist. Aborting"; exit 1; fi

	echo "Creating folder & basic files…"
	mkdir "roles/${ROLE}"
	mkdir "roles/${ROLE}/default"
	mkdir "roles/${ROLE}/files"
	mkdir "roles/${ROLE}/meta"
	touch "roles/${ROLE}/meta/main.yml"
	echo -e "dependencies:\n  - role: base" > "roles/${ROLE}/meta/main.yml"
	mkdir "roles/${ROLE}/tasks"
	touch "roles/${ROLE}/tasks/main.yml"
	mkdir "roles/${ROLE}/templates"
	mkdir "roles/${ROLE}/vars"
	touch "roles/${ROLE}/README.md"
	echo -e "# \`${ROLE}\` role\n\n## Description\n\nPlease describe what this role purpose here." > "roles/${ROLE}/README.md"

	echo "The following file structure has been created:"
	tree roles/${ROLE}

	echo
	echo "The 'base' role has been automatically added as a dependency."
	echo
	echo "Please remove any unused file / folder."
	echo "And don't forget to write a quick documentation on the role purpose :)"

debug-run: are-requirements-ok is-playbook-valid run-ansible-galaxy ## Run a Ansible playbook on a vagrant VM. Usage: `make debug-run PLAYBOOK=< playbook-name >`
	# Testing if the VM already exist or not.
	if [ ! -f ".vagrant/machines/${INTERNAL_VM_NAME}/virtualbox/private_key" ]; then \
		echo -e "\033[0;36mLaunching the VM…\033[0m"; \
		unset VM_NAME; \
		VM_NAME=${INTERNAL_VM_NAME} vagrant up; \
	else \
		echo -e "The VM (${INTERNAL_VM_NAME})is already running ! \033[0;32m:)\033[0m"; \
		echo -e "\nYou may want to destroy it to do a fresh start for the provisioning."; \
		read -p "You can [Ctrl + C] to abort or press [Enter] to continue on the current VM."; \
	fi;

	# Copying the playbook & changing host target dynamically
	echo -e "\033[0;36mChanging playbook host target to match local environment…\033[0m"
	cp playbook/${PLAYBOOK}.yml playbook/${PLAYBOOK}.debug-run.yml
	sed -i -E 's/^- hosts: .+/- hosts: ${INTERNAL_VM_NAME}/g' playbook/${PLAYBOOK}.debug-run.yml

	echo -e "\tGenerated playbook that'll be used is 'playbook/${PLAYBOOK}.debug-run.yml'"

	# Running Ansible
	# Disable know_host checks: it'll all local. We don't want to mess with that each time we do a local test.
	echo -e "\033[0;36mRunning Ansible for playbook '${PLAYBOOK}'…\033[0m"
	ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
		--private-key=.vagrant/machines/${INTERNAL_VM_NAME}/virtualbox/private_key \
		-u vagrant \
		-i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory \
		--vault-password-file secrets/vault_password \
		playbook/${PLAYBOOK}.debug-run.yml

	echo
	echo -e "\033[0;32mAs a reminder, here are the ports mapping used by the VM:\033[0m"
	VM_NAME=${INTERNAL_VM_NAME} vagrant port

	echo
	echo -e "\033[0;32mYou can now ssh into your build VM:\033[0m"
	echo -e "\tmake debug-run-ssh PLAYBOOK=${PLAYBOOK}"

debug-run-ssh: are-requirements-ok is-playbook-valid ## Ssh to a running debug VM
	VM_NAME=${INTERNAL_VM_NAME} vagrant ssh

debug-run-destroy: are-requirements-ok is-playbook-valid ## Destroy a debug VM
	VM_NAME=${INTERNAL_VM_NAME} vagrant destroy

##
# Testing targets
test: run-ansible-galaxy ## Run tests regarding ami-builder content
	echo "Running test on all playbooks…"
	for file in `cd playbook && find . -type f -name '*.yml' ! -name '*.debug-run.yml' ! -name '${RESERVED_PLAYBOOK}.yml' | sed 's/\.yml//1'`; do \
		echo -e -n "\t" && make test-playbook PLAYBOOK=$${file}; \
	done

test-playbook: is-playbook-valid ## Test a specific ansible playbook. Usage: `make test-playbook PLAYBOOK=< playbook-name >`
	# launching the docker test container to run the ansible playbooks
	echo -e -n "Testing '${PLAYBOOK}' playbook…"; \
	docker build . --no-cache --force-rm --quiet --rm -f build/test/Dockerfile --build-arg PLAYBOOK=${PLAYBOOK} > /dev/null
	echo -e " \033[0;36m\u2714\033[0m"

##
# Production targets
run: is-playbook-valid run-ansible-galaxy test-playbook ## Run a playbook on a production server `make run PLAYBOOK=< playbook-name >`
	echo -e "\033[0;36mRunning '${PLAYBOOK}' playbook…\033[0m"
	ansible-playbook \
		--vault-password-file secrets/vault_password \
		--ask-pass \
		--inventory-file inventory/inventory.yml \
		playbook/${PLAYBOOK}.yml
