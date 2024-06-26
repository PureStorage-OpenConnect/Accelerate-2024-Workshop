# Exercise 2.4 - Configuring FlashArray replication schedules

# Objective

Demonstrate the use of the [purefa_pgsched module](https://docs.ansible.com/ansible/latest/collections/purestorage/flasharray/purefa_pgsched_module.html) to manage the local snapshot and replication schedules for a protection group.

# Guide

- The `---` at the top of the file indicates that this is a YAML file.
- The `hosts: localhost`, indicates the play is run on the current host.
- `connection: local` tells the Playbook to run locally (rather than SSHing to itself)
- `gather_facts: true` enables facts gathering.
- The `vars:` parameter is a group of parameters to be used in the playbook.
- `url: flasharray1.testdrive.local` is the management IP address of your FlashArray - change this reflect your local environment.
- `api: e448c603-ecfd-8b4e-fc02-0d742e81a779` is the API token for a user on the FlashArray - change this reflect your local environment.
- `name: LOCAL SNAP SCHEDULE | REPLICATION SCHEDULE` is a user defined description that will display in the terminal output.
- `purefa_pgsched:` tells the task which module to use.
- The `name` parameter tells the module the name of the protection group whose schedule will be affected by the task.
- The `schedule` parameter specifies whether we are working on the local snapshot or the replication schedule.
- The `enabled` parameter defines whether schedule is enabled or not.
- The `snap_frequency` parameter defines the local snapshot frequency in seconds.
- The `replicate_frequency` parameter defines the replication frequency in seconds.
- The `snap_at` parameter defines the preferred time of day that local snapshots are generated when the `snap_frequency` is a multiple of 86400 (ie. 1 day).
- The `replicate_at` parameter defines the preferred time of day that replication snapshots are generated when the `snap_frequency` is a multiple of 86400 (ie. 1 day).
- The `days` parameter defines the number of days to keep the `per_day` local snapshots beyond the `all_for` period before they are eradicated.
- The `per_day` parameter defines the number of `per_day` local snapshots to keep beyond the `all_for` period..
- The `target_per_day` parameter defines the number of `per_day` replica snapshots to keep beyond the `target_all_for` period.
- The `all_for` parameter specifies the number of seconds to keep local snapshots before they are eradicated.
- The `target_all_for` parameter specifies the number of seconds to keep replica snapshots before they are eradicated.
- The `fa_url: "{{url}}"` parameter tells the module to connect to the FlashArray Management IP address, which is stored as a variable `url` defined in the `vars` section of the playbook. This makes this array the source array in the replication pair.
- The `api_token: "{{api}}"` parameter tells the module to connect to the FlashArray using this API token, which is stored as a variable `api` defined in the `vars` section of the playbook.

## Step 1:

Run the playbook - Execute the following:

```
$ ansible-playbook purefa-sched.yml
```

# Playbook Output

```yaml
$ ansible-playbook purefa-sched.yml

PLAY [PROTECTION GROUP SCHEDULING] **************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [localhost]

TASK [LOCAL SNAP SCHEDULE] **********************************************************************************************
changed: [localhost]

TASK [REPLICATION SCHEDULE] *********************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

# Verifying the Solution

Login to the source Pure Storage FlashArray with your web browser.

Navigate to the Protection -> Protection Groups window and select the `workshop-pg` group to see the two replication schedule configurations.

# Going Further

Replication schedules can have blackout periods assigned to them to stop replica snapshots being created in a specific time window. Change the REPLICATION SCHEDULE task previously used to the following and rerun the playbook:

```
    - name: REPLICATION SCHEDULE WITH BLACKOUT
      purestorage.flasharray.purefa_pgsched:
        name: workshop-pg
        schedule: replication
        replicate_frequency: 3600
        target_per_day: 10
        target_all_for: 7
        blackout_start: 2AM
        blackout_end: 7AM
        fa_url: "{{ url }}"
        api_token: "{{ api }}"
```
