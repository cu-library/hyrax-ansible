#! /usr/bin/env bash

ansible-playbook /dev/stdin <<PLAYBOOK
- name: Update readme.
  hosts: 127.0.0.1
  connection: local
  vars_files:
    - "$PWD/vars/common.yml"
  tasks:
    - template:
        src: "$PWD/README.j2"
        dest: "$PWD/README.md"
PLAYBOOK
