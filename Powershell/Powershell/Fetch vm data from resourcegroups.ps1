Connect-AzAccount
$sname=Read-Host "Enter Subscription Name:"
$sid=(Get-AzSubscription -SubscriptionName $sname).Id
Register-AzResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"
Get-AzResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"

$VmResourceGroup = Read-Host "Enter Resource Group Name where the vm is present"

#Fetch vm name from resourcegroup 
$listvm = Get-AzVM -ResourceGroupName $VmResourceGroup
$vms = $listvm.name
Write-Host "VMs present in this Rg are: " $vms

foreach ($VmName in $vms)
{
	$vm = Get-AzVM -VMName $VmName
        $Location = $vm.Location
	Write-Host "Basic Details of the VM : $VmName"

	#get disk
	$Disk = Get-AzDisk -Resourcegroup $VmResourceGroup
	$Disk = $Disk.Id | Select-String -Pattern $VmName
	$count = $Disk.count
	Write-Host "No. of disk present in this vm: $count"
	foreach($D in $Disk)
	{
		$DiskName = ($D -split '/')[-1]
		Write-Host "Name of disk: $Diskname"
	}


	#get size of vm
	$currentVm = Get-AzVM -Name $VmName
	$size = $currentVm.HardwareProfile.VmSize
	Write-Host "The size of the vm is : $size"	

	#NIC
	$nic = $vm.NetworkProfile.NetworkInterfaces
	$networkinterface = ($nic.id -split '/')[-1]
	Write-Host "Network Interface card(NIC) of vm : $networkinterface"

	$nicdetails = Get-AzNetworkInterface -Name $networkinterface

	#Vnet
	$vnet = ($nicdetails.IpConfigurations.subnet.Id -split '/')[-3]
	Write-Host "Vnet name : $vnet"

	#subnet
	$subnet = $nicdetails.IpConfigurations.Subnet
	$subnet = ($nicdetails.IpConfigurations.subnet.Id -split '/')[-1]
	Write-Host "subnet name : $subnet"

	#NSG
	$nsg = ($nicdetails.NetworkSecurityGroup.Id -split '/')[-1]
	Write-Host "NSG name : $nsg"
	Write-Host "      "
	Write-Host "      "

	Start-Sleep -Seconds 10
}




















