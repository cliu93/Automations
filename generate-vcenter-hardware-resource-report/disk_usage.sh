#!/bin/bash
WORK_DIR=/var/lib/rundeck/work/ansible
INTVENTORY_FILE=$WORK_DIR/tmp/MelDataCenterDiskCapacity
ANSIBLE_PLAYBOOK=$WORK_DIR/tmp/MelDataCenterDiskCapacity.yml
TODAY=$(date "+%Y%m%d")

# Prepare inventory file
cat << EOF > $INTVENTORY_FILE
[mysql]
mysql.example.com
[nfs]
nfs.example.com
[Meldc_esxi_hosts]
vsphere01.example.com
vsphere02.example.com
vsphere03.example.com
EOF

# Prepare playbook
cat << EOF > $ANSIBLE_PLAYBOOK
---
- hosts: mysql
  remote_user: root
  gather_facts: no

  tasks:
  - name: Check the zpool usage
    raw: zpool list | sed -n '1p; /mysql/p'
    register: myoutput
  - debug:
      var: myoutput.stdout_lines

- hosts: nfs
  remote_user: root
  gather_facts: no

  tasks:
  - name: Check the zpool usage
    raw: zpool list | sed -n '1p; /data_archives/p'
    register: myoutput
  - debug:
      var: myoutput.stdout_lines
      
- hosts: Meldc_esxi_hosts
  remote_user: root
  gather_facts: no

  tasks:
  - name: Check the local disk usage
    raw: df -h | sed -n '1p; /LocalDisk/p'
    register: myoutput
  - debug:
      var: myoutput.stdout_lines
      
- hosts: vsphere01.example.com
  remote_user: root
  gather_facts: no

  tasks:
  - name: Check the shared disk usage
    raw: df -h | sed -n '1p; /\(VM_SNAPSHOTS\|VDISK\)/p'
    register: myoutput
  - debug:
      var: myoutput.stdout_lines
EOF


# execute playbook
ansible-playbook -i $INTVENTORY_FILE $ANSIBLE_PLAYBOOK | tee $WORK_DIR/DataCenterDiskCapacity/MelDataCenterDiskCapacity.$TODAY.output
