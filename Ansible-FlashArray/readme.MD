## Accelerate 2024 - Automation Workshop

### Ansible Automation with FlashArray

_This Workshop material is a remix of Simon Dodsley's excellent Ansible FlashArray Workshop. The original repository can be found [here](https://github.com/PureStorage-OpenConnect/ansible-flasharray-workshop)_

### The Workshop

This content is a toolkit for demonstrating Ansible's capabilities on the Pure Storage FlashArray by providing hands-on or self-paced training.

The Workshop Lab is pre-configured and ready to go as-is in **Pure's Test Drive** environment. If you are running this workshop in your own environment, you will need to configure the FlashArray and Ansible environment as per the instructions in the original repository.

## To start the Lab:

- On the Windows host, click on the Chrome icon on the desktop and click on the "flasharray1" bookmark to open the FlashArray GUI.
- Login to the flasharray using the credentials provided in the Credentials tab.
- Minmize the browser window and open the terminal by clicking on the "Putty" icon on the desktop.
- Select the "linux1" host and click "Open" to open the terminal.
- Login with the credentials provided in the Credentials tab.
- Change directories to the `ansible-workshop/ansible-flasharray/1.0-get-facts` directory.
- Follow the guide. The internal Guide may be difficult to follow tih the limited space, so it is also avaiable on the desktop and in the GitHub repository as a PDF file.
- Click on this link to open the Guide from the GitHub Repository: [Guide](https://github.com/PureStorage-OpenConnect/ansible-flasharray-workshop/blob/master/Ansible%20FlashArray%20Workshop%20Guide.pdf)

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
