###################################################################################################
# Create SQL Hosting Server 
###################################################################################################

Clear-Host
write-host "SQL Hosting Server for PAAS DB will be created - please be patient..."

$sql_hostname = 'sqlpaas'
$rg_paas = "rg_paas"
$rppassword = "Passw0rd"
$templateuri = 'https://raw.githubusercontent.com/Azure/AzureStack-QuickStart-Templates/master/sql-2014-standalone/azuredeploy.json'
$vmLocalAdminPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("sqlrpadmin", $vmLocalAdminPass) 

$SQLParameters = @{
    "dnsNameForPublicIP" = "$sql_hostname"
    "vmName" = "$sql_hostname"
    "vmTimeZone" = "Pacific Standard Time"
    "sqlInstallationISOUri" = "http://care.dlservice.microsoft.com/dl/download/2/F/8/2F8F7165-BB21-4D1E-B5D8-3BD3CE73C77D/SQLServer2014SP1-FullSlipstream-x64-ENU.iso"
    "assetLocation" = "https://raw.githubusercontent.com/Azure/AzureStack-QuickStart-Templates/master/sql-2014-standalone"
    "vmSize" = "Standard_A3"
    "windowsOSVersion"= "2016-Datacenter"
    "adminUsername" = "sqlrpadmin"
    "adminPassword" = "$vmLocalAdminPass"
}

if (!(Get-AzureRmResourceGroup -ResourceGroupName $rg_paas -ErrorAction SilentlyContinue))
{
    New-AzureRmResourceGroup -Name $rg_paas -Location local 
}

New-AzureRmResourceGroupDeployment `
    -Name "$($sql_hostname)_deployment" `
    -ResourceGroupName $rg_paas `
    -TemplateUri $templateuri `
    -TemplateParameterObject $SQLParameters `
    -Mode Incremental -Verbose 
