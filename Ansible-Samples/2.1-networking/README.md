# Exercise 2.1 - Configuring FlashArray Networking

## Table of Contents

- [Objective](#objective)
- [Guide](#guide)
- [Playbook Output](#playbook-outbook)
- [Solution](#solution)
- [Verifying the Solution](#verifying-the-solution)

# Objective

Demonstrate the use of the [purefa_network module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_network_module.html) to configure netowrk interfaces on a Pure Storage FlashArray.

# Guide

## Step 1:

Using the text editor, create a new file called `purefa-network.yml`.

## Step 2:

Enter the following play definition into `purefa-network.yml`:

```yaml
---
- name: NETWORKING
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

Next, add the following `tasks` to the playbook. These tasks will use the `purefa_network` module to configure a physical interface with an IP setup.

```yaml
tasks:
  - name: SETUP ETHERNET INTERFACE
    purestorage.flasharray.purefa_network:
      name: ct0.eth8
      gateway: 10.34.56.1
      address: "10.34.56.23/24"
      mtu: 9000
      fa_url: "{{ url }}"
      api_token: "{{ api }}"
```

- `name: SETUP ETHERNET INTERFACE` is a user defined description that will display in the terminal output.
- `purefa_network:` tells the task which module to use.
- The `name` parameter tells the module which interface on which controller to configure the ethernet information on.
- The `gateway` parameter is the IP address of gateway for the ethernet subnet.
- The `address` parameter is the IP address to assign to the interface in CIDR notation.
- The `mtu` parameter is the MTU value to use for the interface.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook. This makes this array the source array in the replication pair.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.

Save the file and exit out of the editor.

## Step 4:

Run the playbook - Execute the following:

```
[student1@ansible ~]$ ansible-playbook purefa-network.yml
```

# Playbook Output

The output will look as follows.

```yaml
[student1@ansible ~]$ ansible-playbook purefa-network.yml

PLAY [NETWORKING] **i****************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [SETUP ETHERNET INTERFACE] *****************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Solution

The finished Ansible Playbook is provided here: [purefa-network.yml](https://github.com/PureStorage-OpenConnect/ansible-workshop/blob/master/2.1-networking/purefa-network.yml).

# Verifying the Solution

Login to the source Pure Storage FlashArray with your web browser using the management IP address you set in your YAML file.

Navigate to the Settings -> Network window and look in the Ethernet sub-window for the interface you configured..
