# Exercise 2.5 - Configuring common infrastructire settings on a FlashArray

# Objective

Demonstrate the use of multiple FlashArray modules to configure common infrastructure settings on a FlashArray.

In this example we will set the the NTP servers using the [purefa_ntp module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_ntp_module.html), the DNS servers using the [purefa_dns module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_dns_module.html) and the SYSLOG server using the [purefa_syslog module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_syslog_module.html).

# Guide

- The `---` at the top of the file indicates that this is a YAML file.
- The `hosts: localhost`, indicates the play is run on the current host.
- `connection: local` tells the Playbook to run locally (rather than SSHing to itself)
- `gather_facts: true` enables facts gathering.
- The `vars:` parameter is a group of parameters to be used in the playbook.
- `url: flasharray1.testdrive.local` is the management IP address of your source FlashArray - change this reflect your local environment.
- `api: e448c603-ecfd-8b4e-fc02-0d742e81a779` is the API token for a user on the source FlashArray - change this reflect your local environment.
- `name: CONFIGURE NTP | DNS | SYSLOG` is a user defined description that will display in the terminal output.
- `purefa_*:` tells the task which module to use.
- The other parameters tells the modules what values to use for the appropriate configuration values. More details can be found in the online Ansible Collection documentation.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook. This makes this array the source array in the replication pair.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.

## Step 1:

Run the playbook - Execute the following:

```
$ ansible-playbook purefa-infra.yml
```

# Playbook Output

```yaml
$ ansible-playbook purefa-infra.yml

PLAY [INFRASTRUCTURE SETTINGS] ******************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [CONFIGURE NTP] ****************************************************************************************************
changed: [localhost]

TASK [CONFIGURE DNS] ****************************************************************************************************
changed: [localhost]

TASK [CONFIGURE SYSLOG] *************************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************
localhost                  : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Verifying the Solution

Login to the source (flasharray1) Pure Storage FlashArray with your web browser.

Navigate to the Settings -> System window to see the array configuration. There are sub-windows specifically for Array Time, where the NTP servers are listed, and Syslog Servers.

To see the DNS domain and nameserver settings navigate to Settings -> Network page and look at the DNS Settings sub-window.

# Going Further

Configuring the infrastructure settings is only the tip of the iceberg for FlashArray. Using these and other infrastructure related modules for the FlashArray you can build very complex playbooks to configure and maintain your critical configurations.
