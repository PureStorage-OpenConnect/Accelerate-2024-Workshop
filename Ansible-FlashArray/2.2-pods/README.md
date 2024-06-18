# Exercise 2.2 - Configure ActiveCluster pods

# Objective

Demonstrate the use of the [purefa_pod module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_pod_module.html) to create an ActiveCluster replication pod and then stretch that pod across two connected FlashArrays.

# Guide

- The `---` at the top of the file indicates that this is a YAML file.
- The `hosts: localhost`, indicates the play is run on the current host.
- `connection: local` tells the Playbook to run locally (rather than SSHing to itself)
- `gather_facts: true` enables facts gathering.
- The `vars:` parameter is a group of parameters to be used in the playbook.
- `url: flasharray1.testdrive.local` is the management IP address of your source FlashArray - change this reflect your local environment.
- `api: e448c603-ecfd-8b4e-fc02-0d742e81a779` is the API token for a user on the source FlashArray - change this reflect your local environment.
- `name: CREATE POD | STRETCH POD` is a user defined description that will display in the terminal output.
- `purefa_pod:` tells the task which module to use.
- The `name` parameter tells the module the name of the pod to either create or work with if the pod already exists..
- The `stretch` parameter is the name of the connected target array that the pod is to be stretched to. This name must exactly match the target name shown in the source arrays Array Connections list.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook. This makes this array the source array in the replication pair.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.

## Step 1:

Run the playbook - Execute the following:

```
$ ansible-playbook purefa-pod.yml
```

# Playbook Output

```yaml
$ ansible-playbook purefa-pod.yml

PLAY [ACTIVECLUSTER POD] ************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [CREATE POD] *******************************************************************************************************
changed: [localhost]

TASK [STRETCH POD] ******************************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Verifying the Solution

Login to the source (flasharray1) Pure Storage FlashArray with your web browser.

Navigate to the Storage -> Pods window to see the array connections that have been created from the source side of the connections.

Notice that the Array filed contains both the source and target array names indicating the pod has successfully stretched.

# Going Further

In the pod stretch task you were required to know the exact name of the target array to which the pod was being stretched.

To assist in making this process more automated you can perform a `purefa_info` task on the target array and use the response from this to find the array name automatically and use this in the stretch task.

This bonus exercise allows you to perform the pod stretch in a fully automated fashion.

Add the following information into the `vars` section of the playbook:

```
    target_url: flasharray2.testdrive.local
    target_api: 24a96e35-e0e2-806e-c0cc-eaf45e7fa887
```

Replace the second task in your YAML file, the pod stretch task, with the following:

```
    - name: TARGET INFO
      purestorage.flasharray.purefa_info:
        fa_url: "{{ target_url }}"
        api_token: "{{ target_api }}"
      register: target_array

    - name: STRETCH POD
      purestorage.flasharray.purefa_pod:
        name: pod-1
        stretch: "{{ target_array['purefa_info']['default']['array_name'] }}"
        fa_url: "{{ url }}"
        api_token: "{{ api }}"
```
