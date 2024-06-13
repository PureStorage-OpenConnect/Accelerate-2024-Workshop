# Exercise 1.0 - Using the purefa_info module

## Table of Contents

- [Objective](#objective)
- [Guide](#guide)
- [Playbook Output](#playbook-outbook)
- [Solution](#solution)
- [Going Further](#going-further)

# Objective

Demonstrate the use of the [purefa_info module](https://docs.ansible.com/ansible/devel/collections/purestorage/flasharray/purefa_info_module.html) to get facts (usefule information) from a Pure Storage FlashArray and display them to a terminal window using the [debug module](https://docs.ansible.com/ansible/latest/modules/debug_module.html).

# Guide

Open a terminal window as explained in the setup exercise.
Make sure you are in the home directory.

## Step 1:

Using your favourite text editor, such as `vi`/`vim` or `nano`, create a new file called `purefa-info.yml`.

## Step 2:

Ansible playbooks are **YAML** files. YAML is a structured encoding format that is also extremely human readable (unlike it's subset - the JSON format).

Enter the following play definition into `purefa-info.yml`:

```yaml
---
- name: GRAB FA FACTS
  hosts: localhost
  connection: local
  gather_facts: false
  vars:
    url: flasharray1.testdrive.local
    api: e448c603-ecfd-8b4e-fc02-0d742e81a779
```

- The `---` at the top of the file indicates that this is a YAML file.
- The `hosts: localhost`, indicates the play is run on the current host.
- `connection: local` tells the Playbook to run locally (rather than SSHing to itself)
- `gather_facts: no` disables facts gathering.
- The `vars:` parameter is a group of parameters to be used in the playbook.
- `url: flasharray1.testdrive.local` is the management IP address of your FlashArray - change this reflect your local environment.
- `api: e448c603-ecfd-8b4e-fc02-0d742e81a779` is the API token for a user on the FlashArra - change this reflect your local environment.

## Step 3:

Next, add the first `task`. This task will use the `purefa_info` module to grab useful information from the Pure Storage FlashArray.

```yaml
tasks:
  - name: COLLECT FLASHARRAY FACTS
    purestorage.flasharray.purefa_info:
      gather_subset:
        - minimum
      fa_url: "{{ url }}"
      api_token: "{{ api }}"
    register: array_facts
```

> A play is a list of tasks. Tasks and modules have a 1:1 correlation. Ansible modules are reusable, standalone scripts that can be used by the Ansible API, or by the ansible or ansible-playbook programs. They return information to ansible by printing a JSON string to stdout before exiting.

- `name: COLLECT FLASHARRAY FACTS` is a user defined description that will display in the terminal output.
- `purefa_info:` tells the task which module to use. Everything except `register` is a module parameter defined on the module documentation page.
- The `gather_subset: minimum` parameter tells the module only to minimum/default array information.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.
- `register: array_facts` tells the task to save the output to a variable `array_facts`.

## Step 4:

Next, append the second `task` to above . This task will use the `debug` module to print the output from array_facts variable we registered the facts to.

```yaml
- name: DISPLAY COMPLETE FLASHARRAY MINIMUM INFORMATION
  ansible.builtin.debug:
    var: array_facts
```

- The `name: DISPLAY COMPLETE FLASHARRAY MINIMUM INFORMATION` is a user defined description that will display in the terminal output.
- `debug:` tells the task to use the debug module.
- The `var: array_facts` parameter tells the module to display the variable array_facts.

Save the file and exit out of editor.

## Step 5:

Run the playbook - Execute the following:

```
[student1@ansible ~]$ ansible-playbook purefa-info.yml
```

The output will look as follows.

```yaml
[student1@ansible ~]$ ansible-navigator run purefa-info.yml --mode stdout

PLAY [GRAB FLASHARRAY FACTS] **********************************************************

TASK [COLLECT FLASHARRAY FACTS] *******************************************************
ok: [localhost]

TASK [DISPLAY COMPLETE FLASHARRAY MINIMUM INFORMATION] ********************************
ok: [localhost] => {
    "array_facts": {
        "changed": false,
        "failed": false,
        "purefa_info": {
            "default": {
                "admins": 9,
                "api_versions": [
                    "1.0",
                    "1.1",
                    "1.2",
                    "1.3",
                    "1.4",
                    "1.5",
                    "1.6",
                    "1.7",
                    "1.8",
                    "1.9",
                    "1.10",
                    "1.11",
                    "1.12",
                    "1.13",
                    "1.14",
                    "1.15",
                    "1.16",
                    "1.17",
                    "1.18",
                    "2.0",
                    "2.1"
                ],
                "array_model": "FA-405",
                "array_name": "acme-array-1",
                "connected_arrays": 0,
                "connection_key": "e448c603-ecfd-8b4e-fc02-0d742e81a779",
                "hostgroups": 4,
                "hosts": 10,
                "maintenance_window": [],
                "pods": 0,
                "protection_groups": 10,
                "purity_version": "5.3.17",
                "remote_assist": "disabled",
                "snapshots": 25,
                "volume_groups": 1,
                "volumes": 38
            }
        }
    }
}

PLAY RECAP ********************************************************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## Step 6:

Finally let's append two more tasks to get more specific info from facts gathered, to the above playbook.

```yaml
- name: DISPLAY ONLY THE FLASHARRAY MODEL
  ansible.builtin.debug:
    var: array_facts['purefa_info']['default']['array_model']

- name: DISPLAY ONLY THE PURITY VERSION
  ansible.builtin.debug:
    var: array_facts['purefa_info']['default']['purity_version']
```

- `var: array_facts['purefa_info']['default']['array_model']` displays the model name for the FlashArray
- `array_facts['purefa_info']['default']['purity_version']` displays the Purity version for the FlashArray

> Because the purefa_info module returns useful information in structured data, it is really easy to grab specific information without using regex or filters. Fact modules are very powerful tools to grab specific device information that can be used in subsequent tasks, or even used to create dynamic documentation (reports, csv files, markdown).

## Step 7:

Run the playbook - Save the file and execute the following:

```
[student1@ansible ~]$ ansible-playbook purefa-info.yml
```

# Playbook Output

The output will look as follows.

```yaml
[student1@ansible ~]$ ansible-playbook purefa-info.yml

PLAY [GRAB FLASHARRAY FACTS] **************************************************************************************

TASK [COLLECT FLASHARRAY FACTS] ***********************************************************************************
ok: [localhost]

TASK [DISPLAY COMPLETE FLASHARRAY MINIMUM INFORMATION] *****************************************************************
ok: [localhost] => {
    "array_facts": {
        "changed": false,
        "failed": false,
        "purefa_info": {
            "default": {
                "admins": 9,
                "api_versions": [
                    "1.0",
                    "1.1",
                    "1.2",
                    "1.3",
                    "1.4",
                    "1.5",
                    "1.6",
                    "1.7",
                    "1.8",
                    "1.9",
                    "1.10",
                    "1.11",
                    "1.12",
                    "1.13",
                    "1.14",
                    "1.15",
                    "1.16",
                    "1.17",
                    "1.18",
                    "2.0",
                    "2.1"
                ],
                "array_model": "FA-405",
                "array_name": "sn1-405-c07-27",
                "connected_arrays": 0,
                "connection_key": "e448c603-ecfd-8b4e-fc02-0d742e81a779",
                "hostgroups": 4,
                "hosts": 10,
                "maintenance_window": [],
                "pods": 0,
                "protection_groups": 10,
                "purity_version": "5.3.17",
                "remote_assist": "disabled",
                "snapshots": 25,
                "volume_groups": 1,
                "volumes": 38
            }
        }
    }
}

TASK [DISPLAY ONLY THE FLASHARRAY MODEL] **************************************************************************
ok: [localhost] => {
    "array_facts['purefa_info']['default']['array_model']": "FA-405"
}

TASK [DISPLAY ONLY THE PURITY VERSION] ****************************************************************************
ok: [localhost] => {
    "array_facts['purefa_info']['default']['purity_version']": "5.3.17"
}

PLAY RECAP ********************************************************************************************************
localhost                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Solution

The finished Ansible Playbook is provided here: [purefa-info.yml](https://github.com/PureStorage-OpenConnect/ansible-workshop/blob/master/1.0-get-facts/purefa-facts.yml).

# Going Further

For this bonus exercise add the `tags: debug` parameter (at the task level) to the existing debug task.

```yaml
- name: DISPLAY COMPLETE FLASHARRAY MINIMUM INFORMATION
  ansible.builtin.debug:
    var: array_facts
  tags: debug
```

Now re-run the playbook with the `--skip-tags debug` command line option.

```
ansible-playbook purefa-info.yml --skip-tags debug
```

Ansible will only run three tasks, skipping the `DISPLAY COMPLETE FLASHARRAY MINIMUM INFORMATION` task.

You have finished this exercise. [Click here to return to the lab guide](../README.md)
