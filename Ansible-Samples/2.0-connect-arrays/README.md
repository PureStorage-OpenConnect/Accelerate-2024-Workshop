# Exercise 2.0 - Connecting two FlashArrays for replication

## Table of Contents

- [Objective](#objective)
- [Guide](#guide)
- [Playbook Output](#playbook-outbook)
- [Solution](#solution)
- [Verifying the Solution](#verifying-the-solution)

# Objective

Demonstrate the use of the [purefa_connect module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_connect_module.html) to connect two Pure Storage FlashArrays for replication, either asynchronous or synchronous.

# Guide

## Step 1:

Using the text editor, create a new file called `purefa-connect.yml`.

## Step 2:

Enter the following play definition into `purefa-connect.yml`:

```yaml
---
- name: REPLICATION CONNECTION
  hosts: localhost
  connection: local
  gather_facts: true
  vars:
    url: flasharray1.testdrive.local
    api: e448c603-ecfd-8b4e-fc02-0d742e81a779
    target_url: flasharray2.testdrive.local
    target_api: 24a96e35-e0e2-806e-c0cc-eaf45e7fa887
```

- The `---` at the top of the file indicates that this is a YAML file.
- The `hosts: localhost`, indicates the play is run on the current host.
- `connection: local` tells the Playbook to run locally (rather than SSHing to itself)
- `gather_facts: true` enables facts gathering.
- The `vars:` parameter is a group of parameters to be used in the playbook.
- `url: flasharray1.testdrive.local` is the management IP address of your source FlashArray - change this reflect your local environment.
- `api: e448c603-ecfd-8b4e-fc02-0d742e81a779` is the API token for a user on the source FlashArray - change this reflect your local environment.
- `target_url: flasharray2.testdrive.local` is the management IP address of your target FlashArray - change this reflect your local environment.
- `target_api: 24a96e35-e0e2-806e-c0cc-eaf45e7fa887` is the API token for a user on the target FlashArray - change this reflect your local environment.

## Step 3:

Next, add the following `tasks` to the playbook. These tasks will use the `purefa_connect` module to connect the two Pure Storage FlashArrays in a replication pair. The first `task` will configure an asynchronous replication connection and the second will create a synchronous replication connection.

Note that these can also be used independently. Pick the type of replication you want, or use both is these are required for your environment.

```yaml
tasks:
  - name: CREATE ASYNC CONNECTION
    purestorage.flasharray.purefa_connect:
      target_url: "{{ target_url }}"
      target_api: "{{ target_api }}"
      connection: async
      fa_url: "{{ url }}"
      api_token: "{{ api }}"

  - name: CREATE SYNC CONNECTION
    purestorage.flasharray.purefa_connect:
      target_url: "{{ target_url }}"
      target_api: "{{ target_api }}"
      connection: sync
      fa_url: "{{ url }}"
      api_token: "{{ api }}"
```

- `name: CREATE ASYNC|SYNC CONNECTION` is a user defined description that will display in the terminal output.
- `purefa_connect:` tells the task which module to use.
- The `connection` parameter tells the module the type of replication connection to create. Choices are `async` or `sync`.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook. This makes this array the source array in the replication pair.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.
- The `target_url: "{{target_url}}"` parameter tells the module the management IP address of the target FlashArray, which is stored as a variable `target_url` defined in the `vars` section of the playbook.
- The `target_api: "{{target_api}}"` parameter tells the module the API token to use for the target FlashArray, which is stored as a variable `target_api` defined in the `vars` section of the playbook.

Save the file and exit out of the editor.

## Step 4:

Run the playbook - Execute the following:

```
[student1@ansible ~]$ ansible-playbook purefa-connect.yml
```

# Playbook Output

The output will look as follows.

```yaml
[student1@ansible ~]$ ansible-playbook purefa-connect.yml

PLAY [REPLICATION CONNECTION] *******************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [CREATE ASYNC CONNECTION] ******************************************************************************************
changed: [localhost]

TASK [CREATE SYNC CONNECTION] *******************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Solution

The finished Ansible Playbook is provided here: [purefa-connect.yml](https://github.com/PureStorage-OpenConnect/ansible-workshop/blob/master/2.0-connect-arrays/purefa-connect.yml).

# Verifying the Solution

Login to the source Pure Storage FlashArray with your web browser using the management IP address you set in your YAML file.

Navigate to the Protection -> Array window to see the array connections that have been created from the source side of the connections.

Login to the target Pure Storage FlashArray with your web browser using the management IP address you set in your YAML file.

Navigate to the Protection -> Array window to see the array connections that have been created from the target side of the connections.
