# Exercise 2.2 - Configure asynchronous replication

# Objective

Demonstrate the use of the [purefa_pg module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_pg_module.html) to configure the Protection Group created in [Exercise 1.4](https://github.com/PureStorage-OpenConnect/ansible-flasharray-workshop/blob/master/1.4-pgroup) to replicate to the array connected in [Exercise 2.0](https://github.com/PureStorage-OpenConnect/ansible-flasharray-workshop/blob/master/2.0-connect-arrays).

# Guide

## Step 1:

Using the text editor, create a new file called `purefa-async.yml`.

## Step 2:

Enter the following play definition into `purefa-async.yml`:

```yaml
---
- name: ASYNC SETUP
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

Next, add the following `task` to the playbook. This tasks will use the `purefa_pg` module to start replication of a protection group asynchronously to connected FlashArray.

```yaml
tasks:
  - name: UPDATE PG
    purestorage.flasharray.purefa_pg:
      name: workshop-pg
      target: <<target array name>>
      fa_url: "{{ url }}"
      api_token: "{{ api }}"
```

- `name: UPDATE PG` is a user defined description that will display in the terminal output.
- `purefa_pg:` tells the task which module to use.
- The `name` parameter tells the module the name of the pod to either create or work with if the pod already exists..
- The `target` parameter is the name of the connected target array that the protection group is to replicate to. This name must exactly match the target name shown in the source arrays Array Connections list.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook. This makes this array the source array in the replication pair.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.

Save the file and exit out of the editor.

## Step 4:

Run the playbook - Execute the following:

```
$ ansible-playbook purefa-async.yml
```

# Playbook Output

```yaml
$ ansible-playbook purefa-async.yml

PLAY [ASYNC SETUP] ******************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [UPDATE PG] ********************************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Verifying the Solution

Login to the source Pure Storage FlashArray with your web browser.

Navigate to the Protection -> Protection Groups window and select the Source Protection Group `workshop-pg` to see the target array has been configured.

# Going Further

In the update pg task you were required to know the exact name of the target array to which the pod was being stretched.

To assist in making this process more automated you can perform a `purefa_info` task on the target array and use the response from this to find the array name automatically and use this in the stretch task.

This bonus exercise allows you to perform the pod stretch in a fully automated fashion.

Add the following information into the `vars` section of the playbook:

```
    target_url: flasharray2.testdrive.local
    target_api: 24a96e35-e0e2-806e-c0cc-eaf45e7fa887
```

Replace the task in your YAML file, with the following:

```
    - name: TARGET INFO
      purestorage.flasharray.purefa_info:
        fa_url: "{{ target_url }}"
        api_token: "{{ target_api }}"
      register: target_array

    - name: UPDATE PG
      purestorage.flasharray.purefa_pg:
        name: workshop-pg
        target: "{{ target_array['purefa_info']['default']['array_name'] }}"
        fa_url: "{{ url }}"
        api_token: "{{ api }}"
```
