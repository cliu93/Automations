#!/usr/bin/pwsh
cd /var/lib/rundeck/work/ansible/DataCenterDiskCapacity
$TODAY = Get-Date -Format "yyyyMMdd"

Import-Module "VMware.PowerCLI"
Connect-VIServer -Server x.x.x.x -User 'Administrator@vsphere.local' -Password 'yyyyyyyy'
Get-VMHost | FT -AutoSize > MelDataCenterCpuMemory.$TODAY.output
Get-Content MelDataCenterCpuMemory.$TODAY.output
