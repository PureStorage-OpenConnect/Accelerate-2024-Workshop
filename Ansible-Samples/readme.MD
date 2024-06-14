## Accelerate 2024 - Automation Workshop

### Ansible Automation with FlashArray

_This Workshop material is a remix of Simon Dodsley's excellent Ansible FlashArray Workshop. The original repository can be found [here](https://github.com/PureStorage-OpenConnect/ansible-flasharray-workshop)_

### The Workshop

This content is a toolkit for demonstrating Ansible's capabilities on the Pure Storage FlashArray by providing hands-on or self-paced training.

The Workshop Lab is pre-configured and ready to go as-is in **Pure's Test Drive** environment. If you are running this workshop in your own environment, you will need to configure the FlashArray and Ansible environment as per the instructions in the original repository.

#### Section 1 - Ansible FlashArray Basic (single FA)

- [Exercise 1.0 - Using the purefa_info module](1.0-get-facts)
- [Exercise 1.1 - Adding a host to a FlashArray](1.1-add-host)
- [Exercise 1.2 - Creating volumes on a FlashArray](1.2-add-volumes)
- [Exercise 1.3 - Connecting volumes to a host on a FlashArray](1.3-connect-volumes)
- [Exercise 1.4 - Creating a protection group on a FlashArray](1.4-pgroup)

#### Section 2 - Ansible FlashArray Advanced (requires 2 FAs)

- [Exercise 2.0 - Connecting two FlashArrays for replication](2.0-connect-arrays)
- [Exercise 2.1 - Configuring FlashArray Networking](2.1-networking)
- [Exercise 2.2 - Configure ActiveCluster pods](2.2-pods)
- [Exercise 2.3 - Configuring asynchronous replication](2.3-async-rep)
- [Exercise 2.4 - Configuring FlashArray replication schedules](2.4-schedule)
- [Exercise 2.5 - Configuring common infrastructure settings on a FlashArray](2.5-infra)
