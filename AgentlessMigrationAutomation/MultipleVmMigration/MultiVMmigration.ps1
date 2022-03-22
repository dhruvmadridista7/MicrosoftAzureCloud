#Sign in to your Microsoft Azure subscription
Connect-AzAccount

$sname = 'AVS_POC_VMware_Migration_Accelerator'

#Select your Azure subscription
$sid=(Get-AzSubscription -SubscriptionName $sname).Id
Set-AzContext -SubscriptionId $sid


$ResourceGroupName = 'MigrationTesting'
$ProjectName = 'MultiVmMigration'
$VmName = @("HDS223105","HDS223106")
$TargetResourceGroupName = 'MigrationTesting'
$TargetVirtualNetworkName = 'MultiVmMigration-Vnet'
$MigratedTestVM = @("HDS223105","HDS223106")
$TargetVMSize = @("Standard_DS2_v2","Standard_DS2_v2")
$TargetSubnetName = @("default","default")

#-ResourceGroupName 'MigrationTesting' -ProjectName 'MultiVmMigration' -VmName 'HDS223105','HDS223106' -TargetResourceGroupName 'MigrationTesting' -TargetVirtualNetworkName 'MultiVmMigration-Vnet' -MigratedTestVM 'HDS223105','HDS223106' -TargetVMSize 'Standard_DS2_v2','Standard_DS2_v2'
#-VmName 'HDS223105','HDS223106' -TargetResourceGroupName 'MigrationTesting' -TargetVirtualNetworkName 'MultiVmMigration-Vnet' -MigratedTestVM 'HDS223105','HDS223106' -TargetVMSize 'Standard_DS2_v2','Standard_DS2_v2'
#4.Retrieve the Azure Migrate project

# Get resource group of the Azure Migrate project
$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName

# Get details of the Azure Migrate project
$MigrateProject = Get-AzMigrateProject -Name $ProjectName -ResourceGroupName $ResourceGroup.ResourceGroupName

# View Azure Migrate project details
Write-Output $MigrateProject


#5.Retrieve discovered VMs in an Azure Migrate project

# Get all VMware VMs in an Azure Migrate project
# Get all VMware VMs in an Azure Migrate project
$DiscoveredServers = Get-AzMigrateDiscoveredServer -ProjectName $MigrateProject.Name -ResourceGroupName $ResourceGroup.ResourceGroupName
$count = $DiscoveredServers.count

#try if possible we can get all the vm name from $DiscoveredServers commmands
#we have to put this vmname array in parameter file.
#$VmName = @("enter vm names here")
#$array = New-Object array[] 
$DiscoveredServer = @()
[array]$DiscoveredServer = @()
#$DiscoveredServer = 1,2
for ($i=0; $i -lt $count; $i++)
{
	#$DiscoveredServer[$i] = Get-AzMigrateDiscoveredServer -ProjectName $MigrateProject.Name -ResourceGroupName $ResourceGroup.ResourceGroupName -DisplayName $VmName[$i]

    $DiscoveredServer += Get-AzMigrateDiscoveredServer -ProjectName $MigrateProject.Name -ResourceGroupName $ResourceGroup.ResourceGroupName -DisplayName $VmName[$i]

   # $DiscoveredServer += $vm
   
}

# View discovered servers details
Write-Output $DiscoveredServer




# Initialize replication infrastructure for the current Migrate project

$var = Initialize-AzMigrateReplicationInfrastructure -ResourceGroupName $ResourceGroup.ResourceGroupName -ProjectName $MigrateProject.Name -Scenario agentlessVMware -TargetRegion "Australia East"





#7.Replicate VMs

#Replicate VMs with all disks

# Retrieve the resource group that you want to migrate to
$TargetResourceGroup = Get-AzResourceGroup -Name $TargetResourceGroupName

# Retrieve the Azure virtual network and subnet that you want to migrate to
$TargetVirtualNetwork = Get-AzVirtualNetwork -Name $TargetVirtualNetworkName

$MigrateJob = @()
[array]$MigrateJob = @()
#$MigrateJob = 1,2

#Based on discovered vm commands, we have to change the variable $DiscoveredServer or $DiscoveredServers.
# Start replication for a discovered VM in an Azure Migrate project
for ($i=0; $i -lt $count; $i++)
{
	#here we have to create array of $migratedVMName and $vmsize and enter the values and pass it to the parametre file.
	#also we have to check the vnet subnet ..because there are multiple subnets in the RG.
	$MigrateJob +=  New-AzMigrateServerReplication -InputObject $DiscoveredServer[$i] -TargetResourceGroupId $TargetResourceGroup.ResourceId -TargetNetworkId $TargetVirtualNetwork.Id -LicenseType NoLicenseType -OSDiskID $DiscoveredServer[$i].Disk[0].Uuid -TargetSubnetName $TargetSubnetName[$i] -DiskType Standard_LRS -TargetVMName $MigratedTestVM[$i] -TargetVMSize $TargetVMSize[$i]
}
# Track job status to check for completion
for ($i=0; $i -lt $count; $i++)
{
	while (($MigrateJob[$i].State -eq 'InProgress') -or ($MigrateJob[$i].State -eq 'NotStarted')){
        	#If the job hasn't completed, sleep for 10 seconds before checking the job status again
        	sleep 10;
        	$MigrateJob[$i] = Get-AzMigrateJob -InputObject $MigrateJob[$i]
	}
	#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded".
	Write-Output $MigrateJob[$i].State
}



#I have to change a code in replication..because we have to give only one vmname at one time.
#8. Monitor replication

# List replicating VMs and filter the result for selecting a replicating VM. This cmdlet will not return all properties of the replicating VM.
$ReplicatingServer = @()
[array]$ReplicatingServer = @()
for ($i=0; $i -lt $count; $i++)
{
	$ReplicatingServer += Get-AzMigrateServerReplication -ProjectName $MigrateProject.Name -ResourceGroupName $ResourceGroup.ResourceGroupName -MachineName $VmName[$i]
}

for ($i=0; $i -lt $count; $i++)
{
	while ($ReplicatingServer[$i].MigrationStateDescription -eq 'Initial replication'){
        	#If the job hasn't completed, sleep for 10 seconds before checking the job status again
        	sleep 10;
        	$ReplicatingServer[$i] = Get-AzMigrateServerReplication -ProjectName $MigrateProject.Name -ResourceGroupName $ResourceGroup.ResourceGroupName -MachineName $VmName[$i]
	}
	#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded".
	Write-Output $ReplicatingServer[$i].MigrationStateDescription
}



#11. Run a test migration

# Retrieve the Azure virtual network created for testing
#If you want to use different vnet for testing the migration then also you can use that, or we can use same targetVnet.
$TestVirtualNetworkName = $TargetVirtualNetworkName
$TestVirtualNetwork = Get-AzVirtualNetwork -Name $TestVirtualNetworkName

$TestMigrationJob = @()
[array]$TestMigrationJob = @()
# Start test migration for a replicating server
for ($i=0; $i -lt $count; $i++)
{
	$TestMigrationJob += Start-AzMigrateTestMigration -InputObject $ReplicatingServer[$i] -TestNetworkID $TestVirtualNetwork.Id
}

# Track job status to check for completion
for ($i=0; $i -lt $count; $i++)
{
	while (($TestMigrationJob[$i].State -eq 'InProgress') -or ($TestMigrationJob[$i].State -eq 'NotStarted')){
        	#If the job hasn't completed, sleep for 10 seconds before checking the job status again
        	sleep 10;
        	$TestMigrationJob[$i] = Get-AzMigrateJob -InputObject $TestMigrationJob[$i]
	}
	# Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded".
	Write-Output $TestMigrationJob[$i].State
}



# Clean-up test migration for a replicating server
$CleanupTestMigrationJob = @()
[array]$CleanupTestMigrationJob = @()
for ($i=0; $i -lt $count; $i++)
{
	$CleanupTestMigrationJob += Start-AzMigrateTestMigrationCleanup -InputObject $ReplicatingServer[$i]
}

# Track job status to check for completion
for ($i=0; $i -lt $count; $i++)
{
	while (($CleanupTestMigrationJob[$i].State -eq "InProgress") -or ($CleanupTestMigrationJob[$i].State -eq "NotStarted")){
        	#If the job hasn't completed, sleep for 10 seconds before checking the job status again
        	sleep 10;
        	$CleanupTestMigrationJob[$i] = Get-AzMigrateJob -InputObject $CleanupTestMigrationJob[$i]
	}
	# Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded".
	Write-Output $CleanupTestMigrationJob[$i].State
}




#12. Migrate VMs


# Start migration for a replicating server and turn off source server as part of migration
$FinalMigrateJob = @()
[array]$FinalMigrateJob = @()
for ($i=0; $i -lt $count; $i++)
{
	$FinalMigrateJob += Start-AzMigrateServerMigration -InputObject $ReplicatingServer[$i] -TurnOffSourceServer
}

# Track job status to check for completion
for ($i=0; $i -lt $count; $i++)
{
	while (($FinalMigrateJob[$i].State -eq 'InProgress') -or ($FinalMigrateJob[$i].State -eq 'NotStarted')){
        	#If the job hasn't completed, sleep for 10 seconds before checking the job status again
        	sleep 10;
        	$FinalMigrateJob[$i] = Get-AzMigrateJob -InputObject $FinalMigrateJob[$i]
	}
	#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded".
	Write-Output $FinalMigrateJob[$i].State
}




#13. Complete the migration


# Stop replication for a migrated server
$StopReplicationJob = @()
[array]$StopReplicationJob = @()
for ($i=0; $i -lt $count; $i++)
{
	$StopReplicationJob += Remove-AzMigrateServerReplication -InputObject $ReplicatingServer[$i]
}

# Track job status to check for completion
for ($i=0; $i -lt $count; $i++)
{
	while (($StopReplicationJob[$i].State -eq 'InProgress') -or ($StopReplicationJob[$i].State -eq 'NotStarted')){
        	#If the job hasn't completed, sleep for 10 seconds before checking the job status again
        	sleep 10;
        	$StopReplicationJob[$i] = Get-AzMigrateJob -InputObject $StopReplicationJob[$i]
	}

	# Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded".
	Write-Output $StopReplicationJob[$i].State
}