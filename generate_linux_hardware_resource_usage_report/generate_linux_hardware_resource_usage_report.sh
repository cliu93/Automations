#!/bin/bash
WORK_DIR=/var/lib/rundeck/work/ansible
INTVENTORY_FILE=$WORK_DIR/tmp/EUDataCenterDiskCapacity
ANSIBLE_PLAYBOOK=$WORK_DIR/tmp/EUDataCenterDiskCapacity.yml
TODAY=$(date "+%Y%m%d")

# Prepare inventory file
cat << EOF > $INTVENTORY_FILE
[PROD]
prod.exmaple.com

[DMZ]
dmz.exmaple.com

[UAT]
uat.exmaple.com

[TEST]
test.exmaple.com

[DR]
dr.exmaple.com

[FW]
fw.exmaple.com:2222
EOF

vms="PROD DMZ UAT TEST DR"
for vm in $vms
do
# Prepare playbook
cat << EOF > $ANSIBLE_PLAYBOOK
---
- hosts: $vm
  remote_user: root
  gather_facts: no

  tasks:
  - name: Check the zpool usage
    raw: zpool list | sed -n '1p; /\(lxd\|shared\)/p'
    register: myoutput
  - debug:
      var: myoutput.stdout_lines

  - name: Check the local disk usage
    raw: df -h | sed -n '1p; /xvda2/p'
    register: myoutput
  - debug:
      var: myoutput.stdout_lines

  - name: Check the Memory Usage
    raw: free -m|sed -n '2p'|awk '{print "Memory_Usage:",\$2,\$3,\$4+\$6}'
    register: myoutput
  - debug:
      var:  myoutput.stdout_lines

  - name: Check the CPU Information
    raw: echo "CPU_Info:" \`cat /proc/cpuinfo |grep "model name"|head -1|awk -F ":" '{print \$2}'| sed 's/\s//'|sed 's/\s/_/g'\` \`cat /proc/cpuinfo |grep "model name"|wc -l\` \`vmstat|tail -1|awk '{print \$15}'\`
    register: myoutput
  - debug:
      var:  myoutput.stdout_lines
EOF

# execute playbook
ansible-playbook -i $INTVENTORY_FILE $ANSIBLE_PLAYBOOK | tee $WORK_DIR/DataCenterDiskCapacity/EUDataCenterDiskCapacity_$vm.$TODAY.output
done

# Prepare playbook for FW
cat << EOF > $ANSIBLE_PLAYBOOK
---
- hosts: FW
  remote_user: rundeck
  gather_facts: no

  tasks:
  - name: Check the local disk usage
    raw: df -h | sed -n '1p; /ufs/p'
    register: myoutput
  - debug:
      var: myoutput.stdout_lines

  - name: Check the Memory 
    raw: echo "Memory_Usage:" \`sysctl -n hw.physmem\` \`sysctl -n hw.pagesize\` \`sysctl -n vm.stats.vm.v_inactive_count\` \`sysctl -n vm.stats.vm.v_cache_count\` \`sysctl -n vm.stats.vm.v_free_count\` | awk '{print \$1,\$2/1024/1024,(\$2-(\$4+\$5+\$6)*\$3)/1024/1024,(\$4+\$5+\$6)*\$3/1024/1024}'
    register: myoutput
  - debug:
      var: myoutput.stdout_lines

  - name: Check the CPU Information 
    raw: echo "CPU_Info:" \`sysctl -n hw.model | sed 's/ /_/g'\` \`sysctl -n hw.ncpu\` \`vmstat | tail -1 | awk '{print \$19}'\`
    register: myoutput
  - debug:
      var: myoutput.stdout_lines
EOF

# execute playbook for FW
ansible-playbook -i $INTVENTORY_FILE $ANSIBLE_PLAYBOOK | tee $WORK_DIR/DataCenterDiskCapacity/EUDataCenterDiskCapacity_FW.$TODAY.output

# Generate the excel file
cd $WORK_DIR/DataCenterDiskCapacity
source venv/bin/activate
python EUDcDiskUsage.py
if [ $? -eq 0 ]; then
    echo "Generate Excel file successfully"
else
    echo "Generate Excel file failed, please check with INF team"
    exit 1
fi

# Send Email with the excel file
echo "Hi team, please review the EU DC Capacity report" | mutt -a $WORK_DIR/DataCenterDiskCapacity/EUDC_Capacity_Report.$TODAY.xlsx -s "EU DC Capacity report ${TODAY}" -- @option.requestor@ @option.requestor2@ 
