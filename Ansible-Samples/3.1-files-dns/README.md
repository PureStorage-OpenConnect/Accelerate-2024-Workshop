# Exercise 3.1 - Configuring FA-Files DNS on a FlashArray

## Table of Contents

- [Objective](#objective)
- [Guide](#guide)
- [Playbook Output](#playbook-outbook)
- [Solution](#solution)
- [Verifying the Solution](#verifying-the-solution)

# Objective

Demonstrate the use of the [purefa_dns module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_dns_module.html) to configure the DNS configuration for FA-Files that is seperate to the main FlashArray DNS configuration (also called the management DNS).

**NOTE:** This exercise is applicable only for FlashArrays with FA-Files configured and running Purity//FA 6.3.3 or higher. This functionality also requires the Ansible FlashArray Collection 1.14.0 or higher.

# Guide

## Step 1:

Using the text editor, create a new file called `purefa-file-dns.yml`.

## Step 2:

Enter the following play definition into `purefa-file-dns.yml`:

```yaml
---
- name: FA-FILES DNS
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

Next, add the following `task` to the playbook. This task will use the `purefa_dns` module to configure a DNS setup that is specifically for use with FA-Files.

```yaml
tasks:
  - name: CONFIGURE FILES DNS
    purestorage.flasharray.purefa_dns:
      domain: purestorage.com
      nameservers:
        - dns1.acme.com
        - dns2.acme.com
      name: file_dns
      service: file
      fa_url: "{{ url }}"
      api_token: "{{ api }}"
```

- `name: CONFIGURE FILES DNS` is a user defined description that will display in the terminal output.
- `purefa_dns:` tells the task which module to use.
- `name:` defines the unique name for the DNS service.
- `service: file` tells the FlashArray that you are configuring the DNS file service instead of the default `management` service.
- `domain:` is the domain suffix to be appended when perofrming DNS lookups.
- `nameservers:` is a list of up to 3 unique DNS server IP addresses. These can be FQDN, IPv4 or IPv6.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook. This makes this array the source array in the replication pair.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.

Save the file and exit out of the editor.

## Step 4:

Run the playbook - Execute the following:

```
[student1@ansible ~]$ ansible-playbook purefa-file-dns.yml
```

# Playbook Output

The output will look as follows.

```yaml
[student1@ansible ~]$ ansible-playbook purefa-file-dns.yml

PLAY [FA-FILES DNS] *****************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [CONFIGURE FILES DNS] **********************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Solution

The finished Ansible Playbook is provided here: [purefa-file-dns.yml](https://github.com/PureStorage-OpenConnect/ansible-workshop/blob/master/3.1-files-dns/purefa-file-dns.yml).

# Verifying the Solution

Login to the source Pure Storage FlashArray with your web browser using the management IP address you set in your YAML file.

Navigate to the Storage -> File Systems window to see the new filesystem, directory and export.
