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

$name = "baseplan"
$rg_name = "rg_plans_offers"

if (!(Get-AzureRmResourceGroup -ResourceGroupName $rg_name -ErrorAction SilentlyContinue))
{
    $RG = New-AzureRmResourceGroup -Name $rg_name -Location local
} else {
    $RG = Get-AzureRmResourceGroup -ResourceGroupName $rg_name -ErrorAction SilentlyContinue
}

$ComputeQuota = New-AzsComputeQuota -Name "$($name)_compute" -Location AzureStackAdmin -ErrorAction SilentlyContinue # -VirtualMachineCount 5000
$NetworkQuota = New-AzsNetworkQuota -Name "$($name)_network" -Location AzureStackAdmin -ErrorAction SilentlyContinue # -PublicIpsPerSubscription 20 -VNetsPerSubscription 20 -GatewaysPerSubscription 10 -ConnectionsPerSubscription 1000 -NicsPerSubscription 10000

if (!(get-AzsStorageQuota -Name "$($name)_storage" -Location AzureStackAdmin -ErrorAction SilentlyContinue))
{
    $StorageQuota = New-AzsStorageQuota -Name "$($name)_storage" -Location AzureStackAdmin -NumberOfStorageAccounts 10 -CapacityInGB 500 -SkipCertificateValidation -ErrorAction SilentlyContinue
} else {
    $StorageQuota = get-AzsStorageQuota -Name "$($name)_storage" -Location AzureStackAdmin -ErrorAction SilentlyContinue
}

## create a plan
$PLAN = New-AzsPlan -Name "$($name)_plan" -DisplayName "$name Plan" -ResourceGroupName $rg.ResourceGroupName -QuotaIds $StorageQuota.Id,$NetworkQuota.Id,$ComputeQuota.Id -ArmLocation local
$Offer = New-AzsOffer -Name "$($name)_offer" -DisplayName "$name Offer" -State Public -BasePlanIds $PLAN.Id -ArmLocation local -ResourceGroupName $rg.ResourceGroupName
New-AzsTenantSubscription -DisplayName "$name Subscription" -Owner "Azurestack Admin" -OfferId $Offer.Id 
