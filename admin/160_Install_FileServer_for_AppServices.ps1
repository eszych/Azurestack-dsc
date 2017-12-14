###################################################################################################
# Create FileServer for AppServices 
###################################################################################################

Clear-Host
write-host "FileServer for App-Services will be created - please be patient..."

$fs_hostname = 'fileserver'
$rg_paas = "rg_paas"
$rppassword = "Passw0rd"
$templateuri = 'https://raw.githubusercontent.com/Azure/AzureStack-QuickStart-Templates/master/appservice-fileserver-standalone/azuredeploy.json'
$vmLocalAdminPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("sqlrpadmin", $vmLocalAdminPass) 

$FSParameters = @{
    "fileServerVirtualMachineSize" = "Standard_A2"
    "imageReference" = "MicrosoftWindowsServer | WindowsServer | 2016-Datacenter | latest"
    "dnsNameForPublicIP" = "appServiceFileShare"
    "adminUsername" = "fileshareowner"
    "adminPassword" = $vmLocalAdminPass
    "fileShareOwner" = "fileshareowner"
    "fileShareOwnerPassword" = $vmLocalAdminPass
    "fileShareUser" = "fileshareuser"
    "fileShareUserPassword" = $vmLocalAdminPass
    "vmExtensionScriptLocation" = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/appservice-fileserver-standalone"
}

if (!(Get-AzureRmResourceGroup -ResourceGroupName $rg_paas -ErrorAction SilentlyContinue))
{
    New-AzureRmResourceGroup -Name $rg_paas -Location local 
}

New-AzureRmResourceGroupDeployment `
    -Name "$($fs_hostname)_deployment" `
    -ResourceGroupName $rg_paas `
    -TemplateUri $templateuri `
    -TemplateParameterObject $FSParameters `
    -Mode Incremental -Verbose 
