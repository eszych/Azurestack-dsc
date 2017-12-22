<#
This script performs the necessary steps to install AppServices on a newly created AzureStack System
It must be run as Administrator!
#>

#REQUIRES -RunAsAdministrator

###################################################################################################
# Get the basiscs ready and read the parameters from JSON file 
###################################################################################################

param (
    [Parameter(ParameterSetName = "1", Mandatory = $false, Position = 1)]
    [ValidateScript({ Test-Path -Path $_ })]
    [String] $Defaultsfile="$HOME/admin.json"
)

# Set PS Execution Policy
Set-ExecutionPolicy  -ExecutionPolicy RemoteSigned -force

# Determine script location for PowerShell
$GLOBAL:ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
Write-Host "Current script directory is $ScriptDir"

$DateTime = Get-Date -Format g
Write-Host "Script started at $DateTime"

# Load parameters from a JSON file
write-host "Load parameters from a JSON file"
$Defaultsfile="$ScriptDir/admin.json"
if (!(Test-Path $Defaultsfile)){
    Write-Warning "$Defaultsfile file does not exist. Please copy from admin.json.example"
    Break
} else {
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
$Global:AzSDomain = $Admin_Defaults.Domain
$Global:AzsCloudadmin = "$($Admin_Defaults.Domain)\$($Admin_Defaults.Cloudadmin)"
$Global:RegPath = $Admin_Defaults.RegistryPath
$Global:AzureRmProfile = $Admin_Defaults.AzureRmProfile
$Global:AzureStackModuleVersion = $Admin_Defaults.AzureStackModuleVersion
$Global:Win2016ISO = $Admin_Defaults.Win2016ISO
$Global:UBUNTUVHD = $Admin_Defaults.UBUNTUVHD

# Get Password for AzureStack Service User
write-host "Get Password for AzureStack Service User"
if (!$Global:ServiceAdminCreds)
{
    $Global:ServiceAdminCreds = Get-Credential -UserName $GLobal:ServiceAdmin -Message "Enter Azure ServiceAdmin Password"
}

# Get Password for CloudAdmin
write-host "Get Password for CloudAdmin"
if (!$Global:CloudAdminCreds)
{
    $Global:CloudAdminCreds =  Get-Credential -UserName $Admin_Defaults.Cloudadmin -Message "Enter Azure CloudAdmin Password"
}

#$GLobal:ServiceAdminCreds = $ServiceAdminCreds
#$Global:CloudAdminCreds = $CloudAdminCreds

# Create a RegKey if the script needs to re-run
write-host "Create a RegKey if the script needs to re-run"

IF(!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'First Install Attempt' -Value "$DateTime" -PropertyType STRING -Force | Out-Null
    $KeyNames = ('PowerShell','RegisterAzS','MarketplaceDownload','BasePlan','W2K16Image','UBU1604Image','SQLServer','SQLProvider','SQLHostingSrv','MySQLServer','MySQLProvider','MySQLHostingSrv','FileServer','AppService')
    foreach ($KeyName in $KeyNames)
    {
        New-ItemProperty -Path $RegPath -Name $KeyName -Value $false -PropertyType DWORD -Force | Out-Null
    }
} ELSE {
    New-ItemProperty -Path $RegPath -Name 'Last Install Attempt' -Value "$DateTime" -PropertyType STRING -Force | Out-Null
}

###################################################################################################
# Install the PowerShell Tools and login to the Azure Stack Environment
###################################################################################################
$PowerShellInstallstate = (Get-ItemProperty -Path $RegPath -Name 'PowerShell').PowerShell
IF($PowerShellInstallstate -eq "0" ) {

    .\110_Install_PowerShell_Modules.ps1

    $PSInstallDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'PowerShell Installed' -Value $PSInstallDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'PowerShell' -Value $true -PropertyType DWORD -Force | Out-Null
    
} ELSE {
    write-host "PowerShell Script for Azure Stack already installed - skipping..."
}


# Sign in to your environment
write-host "Logging into the Azure Active Directory Account"
try {
    #Login to your Azure Account to get Subscription ID
    $AzRMAccount = Login-AzureRmAccount -EnvironmentName "AzureCloud" -Credential $Global:ServiceAdminCreds -ErrorAction Stop
}
catch {
    write-host "could not login Azure Active Directory Account $($Global:ServiceAdmin), maybe wrong pasword ? "
    Break	
}

$Global:subscription = $AzRMAccount.Context.Subscription.Id
$Global:TenantID = $AzRMAccount.Context.Tenant.TenantId
Select-AzureRmSubscription -SubscriptionId $subscription
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.AzureStack

# Import Modules to connect to AzS 
write-host "Import Modules to connect to AzS"
Import-Module "$($GLobal:AZSTools_location)\Connect\AzureStack.Connect.psm1" -Force
Import-Module AzureRM.AzureStackStorage -Force
Import-Module "$($Global:AZSTools_location)\serviceAdmin\AzureStack.ServiceAdmin.psm1" -Force
Import-Module "$($Global:AZSTools_location)\ComputeAdmin\AzureStack.ComputeAdmin.psm1" -Force

# For Azure Stack development kit, this value is set to https://adminmanagement.local.azurestack.external. To get this value for Azure Stack integrated systems, contact your service provider.
$Global:ArmEndpoint = "https://adminmanagement.local.azurestack.external"

# For Azure Stack development kit, this value is adminvault.local.azurestack.external 
$Global:KeyvaultDnsSuffix = "adminvault.local.azurestack.external"
$Global:GraphAudience = "https://graph.windows.net/"

# Register an AzureRM environment that targets your Azure Stack instance
Add-AzureRMEnvironment -Name "AzureStackAdmin" -ArmEndpoint $ArmEndpoint
Set-AzureRmEnvironment -Name "AzureStackAdmin" -GraphAudience $GraphAudience

Login-AzureRmAccount -EnvironmentName "AzureStackAdmin" -TenantId $TenantID -Credential $ServiceAdminCreds -ErrorAction Stop

# Get the Active Directory tenantId that is used to deploy Azure Stack
$Global:TenantID = Get-AzsDirectoryTenantId -AADTenantName $TenantName -EnvironmentName "AzureStackAdmin"

write-host ######################################################################
write-host # Azure Stack Initialization finished                                # 
write-host # You may no run the other scripts by pressind ENTER                 # 
write-host # or cancel out (CTRL-C) and run them one by one                     # 
write-host ######################################################################

Pause

###################################################################################################
# Register Azure Stack with Azure for Marketplace Federation
###################################################################################################

$AzSRegstate = (Get-ItemProperty -Path $RegPath -Name 'RegisterAzS').RegisterAzS
IF($AzSRegstate -eq "0" ) {
    
    .\120_Azure_Registration.ps1

    $AzSRegDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'RegisterAzS Installed' -Value $AzSRegDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'RegisterAzS' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "Azure Stack Registration already done - skipping..."
}

###################################################################################################
# Download Items from the Azure Marketplace 
###################################################################################################

$AzSMktplcitem = (Get-ItemProperty -Path $RegPath -Name 'MarketplaceDownload').MarketplaceDownload
IF($AzSMktplcitem -eq "0" ) {

    .\125_Azure_Marketplace_Download.ps1

    $AzSMktplcitemDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'MarketplaceDownload Installed' -Value $AzSMktplcitemDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'MarketplaceDownload' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "Azure Stack Registration already done - skipping..."
}

###################################################################################################
# Create a base plan, an offering and set quotas for IAAS
###################################################################################################

$PlanOfferState = (Get-ItemProperty -Path $RegPath -Name 'BasePlan').BasePlan
IF($PlanOfferState -eq "0" ) {
    
    .\130_Create_Base_Plan.ps1
    
    $PlanOfferDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'BasePlan Installed' -Value $PlanOfferDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'BasePlan' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "Base Plan and Offering already created - skipping..."
}

###################################################################################################
# Upload a Windows Server 2016 Image for PAAS Providers -  SQL, MySQL, FileServer, AppService
###################################################################################################
$W2K16IMGState = (Get-ItemProperty -Path $RegPath -Name 'W2K16Image').W2K16Image
IF($W2K16IMGState -eq "0" ) {

    .\140_Create_Base_Windows_2016_Image.ps1

    $W2K16IMGDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'W2K16Image Installed' -Value $W2K16IMGDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'W2K16Image' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "Windows Server 2016 Image and Gallery Item already created - skipping..."
}

###################################################################################################
# Add an Ubuntu 16.04.3-LTS Image 
###################################################################################################

$UBU1604ImageState = (Get-ItemProperty -Path $RegPath -Name 'UBU1604Image').UBU1604Image
IF($UBU1604ImageState -eq "0" ) {

    .\141_Create_Ubuntu_Linux_16.04.3-LTS_Image.ps1

    $UBU1604ImageDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'UBU1604Image Installed' -Value $UBU1604ImageDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'UBU1604Image' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "Ubuntu 16.04.3-LTS Image and Gallery Item already created - skipping..."
}

###################################################################################################
# Installing SQL Resource Provider 
###################################################################################################

$SQLProviderState = (Get-ItemProperty -Path $RegPath -Name 'SQLProvider').SQLProvider
IF($SQLProviderState -eq "0" ) {

    .\150_deploy-sql-provider.ps1
    
    write-host "SQL Resource Provider will be installed - please be patient..."

    # Code goes here

    $SQLProviderDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'SQLProvider Installed' -Value $SQLProviderDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'SQLProvider' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "SQL Resource Provider already installed - skipping..."
}

###################################################################################################
# Installing MySQL Resource Provider 
###################################################################################################

$MySQLProviderState = (Get-ItemProperty -Path $RegPath -Name 'MySQLProvider').MySQLProvider
IF($MySQLProviderState -eq "0" ) {

    .\151_deploy-mysql-provider.ps1

    write-host "MySQL Resource Provider will be installed - please be patient..."

    # Code goes here

    $MySQLProviderDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'MySQLProvider Installed' -Value $MySQLProviderDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'MySQLProvider' -Value $true -PropertyType DWORD -Force | Out-Null
    
} ELSE {
    write-host "MySQL Resource Provider already installed - skipping..."
}

###################################################################################################
# Create SQL Hosting Server 
###################################################################################################

$SQLServerState = (Get-ItemProperty -Path $RegPath -Name 'SQLServer').SQLServer
IF($SQLServerState -eq "0" ) {

    .\152_deploy_SQL_server.ps1

    $SQLServerDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'SQLServer Installed' -Value $SQLServerDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'SQLServer' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "SQL Hosting Server for PAAS DB already created - skipping..."
}

###################################################################################################
# Create MySQL Hosting Server 
###################################################################################################

$MySQLServerState = (Get-ItemProperty -Path $RegPath -Name 'MySQLServer').MySQLServer
IF($MySQLServerState -eq "0" ) {

    .\153_deploy_MySQL_Server.ps1
 
    $MySQLServerDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'MySQLServer Installed' -Value $MySQLServerDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'MySQLServer' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "MySQL Hosting Server for PAAS DB already created - skipping..."
}

###################################################################################################
# Register SQL Server as DBaaS Hosting Server 
###################################################################################################

$SQLHostingSrvState = (Get-ItemProperty -Path $RegPath -Name 'SQLHostingSrv').SQLHostingSrv
IF($SQLHostingSrvState -eq "0" ) {

    .\154_register-sql-host.ps1

    write-host "SQL DB hosting server will be registered for DBAAS - please be patient..."

    # Code goes here

    $SQLHostingSrvDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'SQLHostingSrv Installed' -Value $SQLHostingSrvDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'SQLHostingSrv' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "SQL DB hosting server already registered for DBAAS - skipping..."
}

###################################################################################################
# Register MySQL Server as DBaaS Hosting Server 
###################################################################################################

$MySQLHostingSrvState = (Get-ItemProperty -Path $RegPath -Name 'MySQLHostingSrv').MySQLHostingSrv
IF($MySQLHostingSrvState -eq "0" ) {

    .\155_register-mysql-host.ps1

    write-host "MySQL DB hosting server will be registered for DBAAS - please be patient..."

    # Code goes here

    $MySQLHostingSrvDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'MySQLHostingSrv Installed' -Value $MySQLHostingSrvDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'MySQLHostingSrv' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "MySQL DB hosting server already registered for DBAAS - skipping..."
}

###################################################################################################
# Install FileServer for App Services 
###################################################################################################

$FileServerState = (Get-ItemProperty -Path $RegPath -Name 'FileServer').FileServer
IF($FileServerState -eq "0" ) {

    .\160_Install_FileServer_for_AppServices.ps1

    $FileServerDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'FileServer Installed' -Value $FileServerDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'FileServer' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "FileServer for App Services already installed - skipping..."
}

###################################################################################################
# Install App-Services 
###################################################################################################

$AppServiceState = (Get-ItemProperty -Path $RegPath -Name 'AppService').AppService
IF($AppServiceState -eq "0" ) {

#    .\165_Install_AppServices.ps1

    write-host "App-Services will be installed - follow the instructions on screen!"

    # Code goes here

    $AppServiceDateTime = Get-Date -Format g
    New-ItemProperty -Path $RegPath -Name 'AppService Installed' -Value $AppServiceDateTime -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'AppService' -Value $true -PropertyType DWORD -Force | Out-Null

} ELSE {
    write-host "App-Services already installed - skipping..."
}

