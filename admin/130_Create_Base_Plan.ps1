###################################################################################################
# Create a base plan, an offering and set quotas for IAAS
###################################################################################################

write-host "Base Plan and Offering be created - please be patient..."

# Login AzureStackAdmin environment
Login-AzureRmAccount -EnvironmentName "AzureStackAdmin" -TenantId $TenantID -Credential $ServiceAdminCreds -ErrorAction Stop
Set-AzureRmEnvironment -Name "AzureStackAdmin"

Import-Module "$($GLobal:AZSTools_location)\Connect\AzureStack.Connect.psm1" -Force
Import-Module AzureRM.AzureStackStorage -Force
Import-Module "$($Global:AZSTools_location)\serviceAdmin\AzureStack.ServiceAdmin.psm1" -Force
Import-Module "$($Global:AZSTools_location)\ComputeAdmin\AzureStack.ComputeAdmin.psm1" -Force

$name = "Base"
$rg_name = "rg_plans_offers"

write-host "Creating Compute Quota..."
$ComputeQuota = New-AzsComputeQuota -Name "$($name)_compute" -Location local # -VirtualMachineCount 5000

write-host "Creating Network Quota..."
$NetworkQuota = New-AzsNetworkQuota -Name "$($name)_network" -Location local # -PublicIpsPerSubscription 20 -VNetsPerSubscription 20 -GatewaysPerSubscription 10 -ConnectionsPerSubscription 1000 -NicsPerSubscription 10000

write-host "Creating Storage Quota..."
New-AzsStorageQuota -Name "$($name)_storage" -Location local -NumberOfStorageAccounts 10 -CapacityInGB 500 -SkipCertificateValidation -ErrorAction SilentlyContinue
$StorageQuota = Get-AzsStorageQuota -Name "$($name)_storage" -Location local

## create a plan
write-host "Creating the Plan..."
$PLAN = New-AzsPlan -Name "$($name)_plan" -DisplayName "$name Plan" -ResourceGroupName $rg_name -QuotaIds $StorageQuota.Id,$NetworkQuota.Id,$ComputeQuota.Id -ArmLocation local
write-host "Creating the Offer..."
$Offer = New-AzsOffer -Name "$($name)_offer" -DisplayName "$name Offer" -State Public -BasePlanIds $PLAN.Id -ArmLocation local -ResourceGroupName $rg_name
write-host "Creating a new Subscription..."
New-AzsTenantSubscription -DisplayName "$name Subscription" -Owner "Azurestack Admin" -OfferId $Offer.Id 
