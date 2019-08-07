#!/bin/bash
inventoryfile=/var/lib/rundeck/git/gpsss.inf/etc/inventory-AU.cfg
containermpapping=/var/lib/rundeck/git/gpsss.inf/etc/container-Mpapping.cfg
snapshotname=upgrade-$(date +"%Y%m%d")

cat $containermpapping | grep -v "^#" |  while IFS="," read -r containerhostname containername vmhostname
do
echo "###### Step 1: Go to $vmhostname to run snapnshot for $containerhostname ######"

#Prepare playbook
cat << EOF > @option.workdir@/tmp/$vmhostname.yml
---
- hosts: all
  remote_user: root
  gather_facts: no

  tasks:
  - name: Take snapshot
    shell: |
      lxc snapshot $containername $snapshotname
      lxc info $containername | grep -A100 "Snapshots"
    register: my
  - debug: var=my.stdout_lines
EOF

#execute playbook
ansible-playbook -i $inventoryfile -l $vmhostname --ssh-extra-args='-o StrictHostKeyChecking=no' @option.workdir@/tmp/$vmhostname.yml

echo "###### Step 2: Go to $containerhostname to run apt-get update and upgrade ######"
#Prepare playbook
cat << EOF > @option.workdir@/tmp/$containerhostname.yml
---
- hosts: all
  remote_user: root
  gather_facts: no
  environment: 
    http_proxy: "{{hostvars[inventory_hostname].proxy}}"
    https_proxy: "{{hostvars[inventory_hostname].proxy}}"

  tasks:
  - name: apt-get update and upgrade
    apt:
      update_cache: yes
      upgrade: yes
EOF

#execute playbook
ansible-playbook -i $inventoryfile -l $containerhostname --ssh-extra-args='-o StrictHostKeyChecking=no' @option.workdir@/tmp/$containerhostname.yml

echo "###### Step 3: Go to $vmhostname to reboot $containerhostname ######"
if [ @option.reboot@ == 'true' ]; then
#Prepare playbook
cat << EOF > @option.workdir@/tmp/$vmhostname.yml
---
- hosts: all
  remote_user: root
  gather_facts: no

  tasks:
  - name: Stop container $containerhostname
    shell: |
      lxc stop $containername
      lxc info $containername | grep "Status"
    register: my
  - debug: var=my.stdout_lines
  
  - name: Start container $containerhostname
    shell: |
      lxc start $containername
      lxc info $containername | grep "Status"
    register: my
  - debug: var=my.stdout_lines  
  
EOF

#execute playbook
ansible-playbook -i $inventoryfile -l $vmhostname --ssh-extra-args='-o StrictHostKeyChecking=no' @option.workdir@/tmp/$vmhostname.yml
else
echo "Reboot is not triggered"
fi

done
