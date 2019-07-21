# Automations
Some automation ideas, I use [Rundeck](www.rundeck.com) to integreate with Bash shell, Ansible, Python script and Poweshell command.

## Generate Vcenter hardware resource report
### Requirements:
- ESXi local disks, SAN disks and NAS share disks usage
- ESXi CPU and Memory usage

In my environment, Mysql Server takes some disk sapce from SAN disk, NFS server takes some disk space from NAS share disk. The other disk space from SAN and NAS are all mounted on all the ESXi servers.

### How to generate the Vcenter hardware resource report?
- Collect Mysql server zpool usage [Bash + Ansible]
- Collect NFS server zpool usage [Bash + Ansible]
- Cpllect ESXi locat disk usage [Bash + Ansible]
- Collect ESXi shared disk usage [Bash + Ansible]
- Collect ESXi CPU and Memory usage [Powershell]
- Generate Execl Report [Python]
