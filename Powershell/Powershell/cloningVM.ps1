connect-azaccount
$sname=Read-Host "Enter Subscription Name"
$sid=(Get-AzSubscription -SubscriptionName $sname).Id
$VmName = Read-Host "Enter VM Name to be cloned"
$VmResourceGroup = Read-Host "Enter Resource Group Name where the vm to be cloned is present"
$Location = Read-Host "Location of Resources"
$OSDiskName = $VmName+'-OS-Managed-Disk'
$DatadiskName = $VmName+'-DataDisk-Managed-Disk'
$StorageType = Read-Host "StorageType(Eg:Standard_LRS)"
$VMSize = Read-Host "Select Vm size (Eg: Standard_D4s_v3)"
$vm = get-azvm -Name $VmName -ResourceGroupName $VmResourceGroup

#OSDisk Snapshot

Write-Output "VM $($vm.name) OS Disk Snapshot Begin"
$snapshotdisk = $vm.StorageProfile
$OSDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $snapshotdisk.OsDisk.ManagedDisk.id -CreateOption Copy -Location $Location -OsType Windows
$snapshotNameOS = "$($snapshotdisk.OsDisk.Name)_snapshot_$(Get-Date -Format ddMMyy)"

#OS Disk Snapshot
 try 
{
   New-AzSnapshot -ResourceGroupName $VmResourceGroup -SnapshotName $snapshotNameOS -Snapshot $OSDiskSnapshotConfig -ErrorAction Stop
}
catch 
{
    $_
}
Write-Output "VM $($vm.name) OS Disk Snapshot End"

	
# Data Disk Snapshots 
Write-Output "VM $($vm.name) Data Disk Snapshots Begin"
$dataDisks = ($snapshotdisk.DataDisks).name
foreach($datadisk in $datadisks) 
{
    $dataDisk = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $datadisk
    Write-Output "VM $($vm.name) data Disk $($datadisk.Name) Snapshot Begin"
    $DataDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $dataDisk.Id -CreateOption Copy -Location $Location
    $snapshotNameData = "$($datadisk.name)_snapshot_$(Get-Date -Format ddMMyy)"
    New-AzSnapshot -ResourceGroupName $VmResourceGroup -SnapshotName $snapshotNameData -Snapshot $DataDiskSnapshotConfig -ErrorAction Stop
    Write-Output "VM $($vm.name) data Disk $($datadisk.Name) Snapshot End"   
}
Write-Output "VM $($vm.name) Data Disk Snapshots End"
Select-AzSubscription -SubscriptionId $sid
$OSSnapshot = Get-AzSnapshot -ResourceGroupName $VmResourceGroup -SnapshotName $snapshotNameOS
$OSDiskConfig = New-AzDiskConfig -AccountType $StorageType -Location $Location -CreateOption Copy -SourceResourceId $OSSnapshot.Id
$OSDisk = New-AzDisk -Disk $OSdiskConfig -ResourceGroupName $VmResourceGroup -DiskName $OSDiskName 
$DataSnapshot = Get-AzSnapshot -ResourceGroupName $VmResourceGroup -SnapshotName $snapshotNameData 
$DatadiskConfig = New-AzDiskConfig -AccountType $StorageType -Location $Location -CreateOption Copy -SourceResourceId $DataSnapshot.Id 
$Datadisk = New-AzDisk -Disk $DatadiskConfig -ResourceGroupName $VmResourceGroup -DiskName $DataDiskName
$VNetName = 'Demo-vnet'
$VMIdentity = $VmName+'-Clone'
$pip = New-AzPublicIpAddress -Name "ClonepublicIP$(Get-Random)" -ResourceGroupName $VmResourceGroup -Location $Location -AllocationMethod Static
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name CloneNetworkSecurityGroupRuleRDP  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $VmResourceGroup -Location $Location -Name CloneNetworkSecurityGroup -SecurityRules $nsgRuleRDP
$RGNameVnet ='Demo'
$vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $RGNameVnet
$nic = New-AzNetworkInterface -Name CloneNic -ResourceGroupName $VmResourceGroup -Location $Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
$VirtualMachine = New-AzVMConfig -VMName $VMIdentity -VMSize $VMSize
$VirtualMachine = Add-AzVMDataDisk -VM $VirtualMachine -Name $dataDiskName -ManagedDiskId $datadisk.id -Lun "0" -CreateOption "Attach"
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -ManagedDiskId $osdisk.Id -CreateOption Attach -Windows
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id
New-AzVM -VM $VirtualMachine -ResourceGroupName $VmResourceGroup -Location $Location
Write-Output "VM cloning done"