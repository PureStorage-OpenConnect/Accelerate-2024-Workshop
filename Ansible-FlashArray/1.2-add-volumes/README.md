# Exercise 1.2 - Adding volumes to a FlashArray

# Objective

Demonstrate the use of the [purefa_volume module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_volume_module.html) to add a host to a Pure Storage FlashArray.

# Guide

## Step 1:

Using the text editor, create a new file called `purefa-volume.yml`.

## Step 2:

Enter the following play definition into `purefa-volume.yml`:

```yaml
---
- name: VOLUME SETUP
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
- `url: flasharray1.testdrive.local` is the management IP address of your FlashArray - change this reflect your local environment.
- `api: e448c603-ecfd-8b4e-fc02-0d742e81a779` is the API token for a user on the FlashArra - change this reflect your local environment.

## Step 3:

Next, add the first `task` to the playbook. This task will use the `purefa_volume` module to create three volume object on the Pure Storage FlashArray.

```yaml
tasks:
  - name: CREATE VOLUMES
    purestorage.flasharray.purefa_volume:
      name: volume_{{ item }}
      size: 32G
      fa_url: "{{ url }}"
      api_token: "{{ api }}"
    loop:
      - a
      - b
      - c
```

- `name: CREATE VOLUMES` is a user defined description that will display in the terminal output.
- `purefa_volume:` tells the task which module to use.
- The `name` parameter tells the module the name of the volume to create. The `{{ item }}` varable instructs Ansible with the `loop` value.
- The `size` parameter tells the module the size to create the volume. The size identifier can be in `b`, `k`, `M`, `G`, `T` or `P`.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.
- `loop:` tells the task to loop over the provided list. The list in this case is the suffix to be appended to the volume name.

Save the file and exit out of the editor.

## Step 4:

Run the playbook - Execute the following:

```
$ ansible-playbook purefa-volume.yml
```

# Playbook Output

The output will look something like this.

```yaml
$ ansible-playbook purefa-volume.yml

PLAY [VOLUME SETUP] *****************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [CREATE VOLUMES] ***************************************************************************************************
changed: [localhost] => (item=a)
changed: [localhost] => (item=b)
changed: [localhost] => (item=c)

PLAY RECAP **************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Verifying the Solution

Login to the Pure Storage FlashArray with your web browser.

The list of volumes configured in the array can be found by navigating the menu on the left to Storage, then selecting the top menu item Volumes.

# Going Further

Feel free to edit the .yml file and replace any of the variables to create different volumes on the FlashArray.

```

```
