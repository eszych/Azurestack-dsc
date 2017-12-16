###################################################################################################
# Create FileServer for AppServices 
###################################################################################################

write-host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
write-host "!!! This script requires User Intervention                                             !!!"
write-host "!!! Please follow the docs under to following link:                                    !!!"
write-host "!!! https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-app-service-deploy  !!!"
write-host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

Pause

$prefix = "AzS"
$privilegedEndpoint = "$prefix-ERCS01"
$rg_paas = "rg_paas"
$rppassword = $Global:VMPassword
$TenantName = $Global:TenantName

# Set the credentials for the Resource Provider VM
$vmLocalAdminPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("sqlrpadmin", $vmLocalAdminPass) 
$PfxPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 

# Point to the directory where the RP installation files will be stored
$APPSVC_DIR = 'D:\TEMP\Appservice'
Remove-Item $APPSVC_DIR -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
$Dir = New-Item -ItemType Directory $APPSVC_DIR -Force
Push-Location $APPSVC_DIR

Invoke-WebRequest https://aka.ms/appsvconmashelpers -OutFile AppServiceHelperScripts.zip
Expand-Archive AppServiceHelperScripts.zip
Invoke-WebRequest https://aka.ms/appsvconmasinstaller -OutFile AppService.exe

$TenantArmEndpoint = "management.local.azurestack.external"
$AdminArmEndpoint = "adminmanagement.local.azurestack.external"

Push-Location .\AppServiceHelperScripts
.\Create-AppServiceCerts.ps1 -PfxPassword $PfxPass -DomainName "local.azurestack.external"
.\Get-AzureStackRootCert.ps1 -PrivilegedEndpoint $privilegedEndpoint -CloudAdminCredential $Global:CloudAdminCreds

# Requires Azure Login Credentials  
.\Create-AADIdentityApp.ps1 `
    -DirectoryTenantName $TenantName `
    -AdminArmEndpoint $AdminArmEndpoint `
    -TenantArmEndpoint $TenantArmEndpoint `
    -CertificateFilePath (join-path (get-location).Path "sso.appservice.local.azurestack.external.pfx") `
    -CertificatePassword $PfxPass

write-host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
write-host "!!! This script requires User Intervention                                             !!!"
write-host "!!! Please follow the docs under to following link:                                    !!!"
write-host "!!! https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-app-service-deploy  !!!"
write-host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

Pause

pop-location
$Argumentlist = "/logfile "+$APPSVC_DIR+"\Appservice\appservice.log"
Start-Process ".\AppService.exe" -ArgumentList $Argumentlist -Wait