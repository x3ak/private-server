FROM williamyeh/ansible:alpine3

# Make build dynamic
ARG PLAYBOOK=

WORKDIR /app/test
COPY . /app/test

# Checking playbook syntax
RUN ansible-playbook --connection=local --vault-password-file secrets/vault_password --syntax-check playbook/${PLAYBOOK}.yml
