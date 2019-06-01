# `docker-gc` role

This role will install a docker garbage collector service.

## Details

A docker garbage collector avoid to have a disk full of pulled images that are not used or stopped containers.

The garbage collector used is [spotify/docker-gc](https://github.com/spotify/docker-gc).
It's ran over a crontab every hour.

## Ignored images

Some docker images can be ignored with the `files/docker-gc-exclude` file.
