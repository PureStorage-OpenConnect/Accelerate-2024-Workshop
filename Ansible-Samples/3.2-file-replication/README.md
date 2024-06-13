# Exercise 3.2 - Configuring FA-Files replication

## Table of Contents

- [Objective](#objective)
- [Guide](#guide)
- [Playbook Output](#playbook-outbook)
- [Solution](#solution)
- [Verifying the Solution](#verifying-the-solution)

# Objective

Demonstrate the use of the [purefa_fs module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_fs_module.html) to create a replicated filesystem.

This module requires that [Exercise 2.0]() and [Exercise 2.2]() have been completed.

**NOTE:** This exercise is applicable only for FlashArrays with FA-Files configured and running Purity//FA 6.3.0 or higher.

# Guide

## Step 1:

Using the text editor, create a new file called `purefa-file-repl.yml`.

## Step 2:

Enter the following play definition into `purefa-file-repl.yml`:

```yaml
---
- name: FILES REPLICATION
  hosts: localhost
  connection: local
  gather_facts: true
  vars:
    url: flasharray1.testdrive.local
    api: e448c603-ecfd-8b4e-fc02-0d742e81a779
```

- The `---` at the top of the file indicates that this is a YAML file.
- The `hosts: localhost`, indicates the play is run on the current host.
- `connection: local` tells the Playbook to run locally (rather than SSHing to itself)
- `gather_facts: true` enables facts gathering.
- The `vars:` parameter is a group of parameters to be used in the playbook.
- `url: flasharray1.testdrive.local` is the management IP address of your source FlashArray - change this reflect your local environment.
- `api: e448c603-ecfd-8b4e-fc02-0d742e81a779` is the API token for a user on the source FlashArray - change this reflect your local environment.

## Step 3:

Next, add the following `task` to the playbook. This task will use the `purefa_fs` module to create a replicated filesystem i nan existing ActiveCluster pod.

```yaml
tasks:
  - name: CREATE REPLICATED FILESYSTEM
    purestorage.flasharray.purefa_fs:
      name: workshop::repl_fs
      fa_url: "{{ url }}"
      api_token: "{{ api }}"
```

- `name: CREATE REPLICATED FILESYSTEM` is a user defined description that will display in the terminal output.
- `purefa_fs:` tells the task which module to use.
- `name:` defines the name of the filesystem to create and the pod it will reside in.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook. This makes this array the source array in the replication pair.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.

Save the file and exit out of the editor.

## Step 4:

Run the playbook - Execute the following:

```
[student1@ansible ~]$ ansible-playbook purefa-file-repl.yml
```

# Playbook Output

The output will look as follows.

```yaml
[student1@ansible ~]$ ansible-playbook purefa-file-repl.yml

PLAY [FILES REPLICATION] ************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [CREATE REPLICATED FILESYSTEM] *************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Solution

The finished Ansible Playbook is provided here: [purefa-file-repl.yml](https://github.com/PureStorage-OpenConnect/ansible-workshop/blob/master/3.2-file-replication/purefa-file-repl.yml).

# Verifying the Solution

Login to the source Pure Storage FlashArray with your web browser using the management IP address you set in your YAML file.

Navigate to the Storage -> File Systems window to see the new replicated filesystem.
