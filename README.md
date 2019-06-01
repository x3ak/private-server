# Image builder

The image builder is based on the following technologies:
 - Ansible, for recipe declaration
 - Ansible Galaxy, for third party resources
 - Vagrant, for local testing
 - Docker, for CI testing

All recipes are written to work on **Red Hat Enterprise Linux**, also know as **CentOs**.

All interactions are done with the `make` command. You can just run `make` or `make help` to list all the available commands.

You can test if you have the correct tools installed by running `make are-requirements-ok`.

## Tests

To test all the playbooks, simply run `make test`. To test a specific one, run `make test-playbook PLAYBOOK=< playbook-name >`.

## Builds

### Local builds

Local builds uses Vagrant to run.
The playbook is copied & modified on the fly to match the local environment, so no remote host will be used.

You can test more than one playbook at a time, it'll launch a new VM for each playbook without any conflict - other than network ports.

#### Local testing

When writing a new playbook / role, you can test it locally by running the following command: `make debug-run PLAYBOOK=< playbook-name >`.
It'll spin up a vagrant VM & run ansible on it.

#### SSH on a build VM

Once the build is finished, you can shh on it by running this command: `make debug-run-ssh PLAYBOOK=< playbook-name >`.

#### Cleanup

You must delete unused VM manually by running `make debug-run-destroy PLAYBOOK=< playbook-name >`.

## Production builds

Run `make run PLAYBOOK=< playbook-name >` and ensure `inventory/inventory.ini` is properly set.