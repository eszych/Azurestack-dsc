﻿[CmdletBinding(HelpUri = "https://github.com/bottkars/azurestack-dsc")]
param (
[Parameter(ParameterSetName = "1", Mandatory = $false,Position = 1)][ValidateScript({ Test-Path -Path $_ })]$Defaultsfile="$HOME/admin.json"
)

if (!(Test-Path $Defaultsfile))
{
    Write-Warning "$Defaultsfile file does not exist.please copy from admin.json.example"
    Break
}
else
    {
    Write-Host -ForegroundColor Gray " ==>loading Admin Enviromment from $Defaultsfile"
    try {
        $Admin_Defaults = Get-Content $Defaultsfile | ConvertFrom-Json -ErrorAction SilentlyContinue   
    }
    catch {
        Write-Host "could not load $Defaultsfile, maybe a format error ?"
        break
    }
    
    Write-Output $Admin_Defaults
    }

$Global:VMPassword = $Admin_Defaults.VMPassword
$Global:TenantName = $Admin_Defaults.TenantName
$Global:ServiceAdmin = "$($Admin_Defaults.serviceuser)@$Global:TenantName"
$Global:AZSTools_location = $Admin_Defaults.AZSTools_Location
$CloudAdmin = "$($Admin_Defaults.Domain)\$($Admin_Defaults.Cloudadmin)"

if (!$Global:ServiceAdminCreds)
    {
    $ServiceAdminCreds = Get-Credential -UserName $GLobal:serviceAdmin -Message "Enter Azure ServiceAdmin Password"
    }
if (!$Global:CloudAdminCreds)
    {
    $CloudAdminCreds =  Get-Credential -UserName $CloudAdmin -Message "Enter Azure CloudAdmin Password for $Cloudadmin" 
    }

Pause    
Import-Module "$($GLobal:AZSTools_location)\Connect\AzureStack.Connect.psm1" -Force
Import-Module AzureRM.AzureStackStorage -Force
Import-Module "$($Global:AZSTools_location)\serviceAdmin\AzureStack.ServiceAdmin.psm1" -Force
Import-Module "$($Global:AZSTools_location)\ComputeAdmin\AzureStack.ComputeAdmin.psm1" -Force

# For Azure Stack development kit, this value is set to https://adminmanagement.local.azurestack.external. To get this value for Azure Stack integrated systems, contact your service provider.
$Global:ArmEndpoint = "https://adminmanagement.local.azurestack.external"

# For Azure Stack development kit, this value is adminvault.local.azurestack.external 
$Global:KeyvaultDnsSuffix = “adminvault.local.azurestack.external”


# Register an AzureRM environment that targets your Azure Stack instance
  Add-AzureRMEnvironment `
    -Name "AzureStackAdmin" `
    -ArmEndpoint $ArmEndpoint

# Get the Active Directory tenantId that is used to deploy Azure Stack
  $Global:TenantID = Get-AzsDirectoryTenantId `
    -AADTenantName $TenantName `
    -EnvironmentName "AzureStackAdmin"

# Sign in to your environment
try {

 Login-AzureRmAccount `
    -EnvironmentName "AzureStackAdmin" `
    -TenantId $TenantID -Credential $ServiceAdminCreds -ErrorAction Stop
}
catch  {
    write-host "could not login AzureRMAccount $($Global:ServiceAdmin), maybe wrong pasword ? "
    Break	
}
$GLobal:ServiceAdminCreds = $ServiceAdminCreds