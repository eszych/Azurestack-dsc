###################################################################################################
# Register Azure Stack with Azure for Marketplace Federation
###################################################################################################

write-host "Azure Stack registration will be started - please be patient..."

Import-Module "$($GLobal:AZSTools_location)\Registration\RegisterWithAzure.psm1" -Force

#Login to your Azure Account to get Subscription ID
$AzRMAccount = Login-AzureRmAccount -EnvironmentName "AzureCloud" -Credential $Global:ServiceAdminCreds -ErrorAction Stop
Set-AzureRmEnvironment -Name "AzureCloud"

$AzureContext = Get-AzureRmContext

Add-AzsRegistration `
    -CloudAdminCredential $Global:CloudAdminCreds `
    -AzureSubscriptionId $AzureContext.Subscription.Id `
    -AzureDirectoryTenantName $AzureContext.Tenant.TenantId `
    -PrivilegedEndpoint AzS-ERCS01 `
    -BillingModel Development 
