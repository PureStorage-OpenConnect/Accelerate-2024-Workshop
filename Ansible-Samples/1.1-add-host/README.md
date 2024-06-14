# Exercise 1.1 - Adding hosts to a FlashArray

# Objective

Demonstrate the use of the [purefa_host module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_host_module.html) to add a host to a Pure Storage FlashArray.

## Step 1:

Run the playbook - Execute the following:

```
$ ansible-playbook purefa-host.yml
```

# Playbook Output

The output will look something like this.

```yaml
$ ansible-playbook purefa-host.yml

PLAY [HOST SETUP] *******************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [CREATE HOST] ******************************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Verifying the Solution

On the Windows host, open a browser and navigate to the Pure Storage FlashArray management interface by clicking on the "flasharray1" shortcut.
Login as the "workshop" with a password of Pureuser!
Go to Storage --> Hosts and verify that the host "ansiblehost" has been added.
