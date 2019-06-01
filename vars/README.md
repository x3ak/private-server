# Ansible vault sum-up

Each vault file should have a markdown file that describe the scheme of the vault.
This will avoid us to decrypt it each time we need to use one of the values.

## Quickly watch values of a vault

Just run the following command:
```console
$ ansible-vault view --vault-password-file=secrets/vault_password vars/< vault-file >.vault
```
