# Ansible FlashArray Workshop
This content is a toolit for demonstrating Ansible's capabilities on the Pure Storage FlashArray by providing hands-on, or self-paced training.

## Workshop Pre-Requisites
You will need access to a Linux server with the latest version of Ansible installed. The Workshop was validated on Ubuntu, therefore if you are using CentOS or RHEL, you may been to install additional packages for some of the Linux tasks.

Your Linux server should have either iSCSI or FC connectivity to the FlashArray(s) and network access to the FlashArray management port.

This will provde the FlashArray Collections, but to ensure you have the latest version of the Collection please run the following command:

`ansible-galaxy collection install purestorage.flasharray --upgrade`

Ensure you have the Pure Storage python SDK installed as well.

`pip3 install purestorage`

`pip3 install py-pure-client`

To run Section 1 of the Workshop will require one FlashArray, running a minimum Purity//FA of 6.1.3. This should have iSCSI or FC connectivity that will allow
connectivity to your Linux host.

Section 2 of the Workshop requires a second FlashArray, running the same Purity//FA version as your first array. There should be network connectivity between the two arrays to allow the replication exercises to run correctly.

Section 3 of the Workshop requires that your FlashArrays are enabled for FA-Files.

## Section 1 - Ansible FlashArray Basic Exercises

 - [Exercise 1.0 - Using the purefa_info module](1.0-get-facts)
 - [Exercise 1.1 - Adding a host to a FlashArray](1.1-add-host)
 - [Exercise 1.2 - Creating volumes on a FlashArray](1.2-add-volumes)
 - [Exercise 1.3 - Connecting volumes to a host on a FlashArray](1.3-connect-volumes)
 - [Exercise 1.4 - Creating a protection group on a FlashArray](1.4-pgroup)

## Section 2 - Ansible FlashArray Advanced Exercises

 - [Exercise 2.0 - Connecting two FlashArrays for replication](2.0-connect-arrays)
 - [Exercise 2.1 - Configuring FlashArray Networking](2.1-networking)
 - [Exercise 2.2 - Configure ActiveCluster pods](2.2-pods)
 - [Exercise 2.3 - Configuring asynchronous replication](2.3-async-rep)
 - [Exercise 2.4 - Configuring FlashArray replication schedules](2.4-schedule)
 - [Exercise 2.5 - Configuring common infrastructure settings on a FlashArray](2.5-infra)

## Section 3 - Ansible FlashArray FA-Files Exercises

This section requires that your FlashArray has been enabled by Pure Support to use FA-Files.

 - [Exercise 3.0 - Creating directories and exports on a FlashArray](3.0-exports)
 - [Exercise 3.1 - Configuring FA-Files DNS on a FlashArray](3.1-files-dns)
 - [Exercise 3.2 - Configuring FA-Files replication](3.2-files-replication)

## Advanced Information

There is a lot of file editing involved in the above exercises, particularly when setting the FA IP and API tokens in every playbook.

An advanced method to use to reduce the amount of editing involves using Ansible command-line variabels using the `-e` switch for `ansible-playbook` and shell variables.

Set the following shell variables before running any playbooks:

```
# export PUREFA_API=<array 1 api token>
# export PUREFA_URL=<array 1 IP address/FQDN>
# export TARGET_API=<array 2 api token>
# export TARGET_URL=<array2 IP address/FQDN>
```

You can then run each exercise playbook using the following commands which will override the parameters in the playbooks for the variables required in each task.

`ansible-playbook -e url=$PUREFA_URL -e api=$PUREFA_API <exercise playbook>.yml`

You can use as many `-e` switches as necessary, depending on how many and which parameters you want to override through the command-line.

Remmeber that if you don't specifiy a parameter using `-e` that is required by a task, the task will use the parameter value set in the `vars:` section of the playbook.


