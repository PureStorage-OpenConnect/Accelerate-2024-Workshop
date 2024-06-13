# Exercise 3.0 - Creating directories and exports on a FlashArray

## Table of Contents

- [Objective](#objective)
- [Guide](#guide)
- [Playbook Output](#playbook-outbook)
- [Solution](#solution)
- [Verifying the Solution](#verifying-the-solution)

# Objective

Demonstrate the use of the [purefa_fs module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_fs_module.html), [purefa_directory module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_directory_module.html) and [purefa_export module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_export_module.html) to create a filesystem with a managed directory that is exposed to users.

# Guide

## Step 1:

Using the text editor, create a new file called `purefa-directory.yml`.

## Step 2:

Enter the following play definition into `purefa-directory.yml`:

```yaml
---
- name: FA-FILES SETUP
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

Next, add the following `tasks` to the playbook. These tasks will use the `purefa_fs`, `purefa_directory` and `purefa_export` modules to create a filesystem with a directory and then exports this for user consumption.

Note that these can also be used independently. Pick the type of replication you want, or use both is these are required for your environment.

```yaml
tasks:
  - name: CREATE FILESYSTEM
    purestorage.flasharray.purefa_fs:
      name: workshop
      fa_url: "{{ url }}"
      api_token: "{{ api }}"

  - name: CREATE DIRECTORY
    purestorage.flasharray.purefa_directory:
      name: dir1
      filesystem: workshop
      fa_url: "{{ url }}"
      api_token: "{{ api }}"

  - name: EXPORT DIRECTORY
    purestorage.flasharray.purefa_export:
      name: workshop_dir
      directory: dir1
      filesystem: workshop
      nfs_policy: nfs-simple
      fa_url: "{{ url }}"
      api_token: "{{ api }}"
```

- `name: CREATE FILESYSTEM | CREATE DIRECORY | EXPORT DIRECTORY` is a user defined description that will display in the terminal output.
- `purefa_*:` tells the task which module to use.
- The `name` parameter tells the module what to call the filesystem, directory and export.
- The `filesystem` parameter tells the module which filesystem the directory is in.
- The `nfs_policy` parameter tells the module the pre-existing export policy to use to allow access to the exported directory. In this example we are using the default `nfs-simple` policy.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook. This makes this array the source array in the replication pair.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.

Save the file and exit out of the editor.

## Step 4:

Run the playbook - Execute the following:

```
[student1@ansible ~]$ ansible-playbook purefa-directory.yml
```

# Playbook Output

The output will look as follows.

```yaml
[student1@ansible ~]$ ansible-playbook purefa-connect.yml

PLAY [FA-FILES SETUP] ***************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [CREATE FILESYSTEM] ************************************************************************************************
changed: [localhost]

TASK [CREATE DIRECORY] **************************************************************************************************
changed: [localhost]

TASK [EXPORT DIRECORY] **************************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************
localhost                  : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Solution

The finished Ansible Playbook is provided here: [purefa-directory.yml](https://github.com/PureStorage-OpenConnect/ansible-workshop/blob/master/3.0-directory/purefa-directory.yml).

# Verifying the Solution

Login to the source Pure Storage FlashArray with your web browser using the management IP address you set in your YAML file.

Navigate to the Storage -> File Systems window to see the new filesystem, directory and export.
