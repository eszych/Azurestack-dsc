###################################################################################################
# Create FileServer for AppServices 
###################################################################################################

write-host "FileServer for App-Services will be created - please be patient..."

$fs_hostname = 'fileserver'
$rg_paas = "rg_paas"
$rppassword = "Passw0rd"
$templateuri = 'https://raw.githubusercontent.com/Azure/AzureStack-QuickStart-Templates/master/appservice-fileserver-standalone/azuredeploy.json'
$vmLocalAdminPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("sqlrpadmin", $vmLocalAdminPass) 

$FSParameters = @{}
$FSParameters.Add("fileServerVirtualMachineSize","Standard_A2")
$FSParameters.Add("adminPassword","$vmLocalAdminPass")
$FSParameters.Add("fileShareOwnerPassword","$vmLocalAdminPass")
$FSParameters.Add("fileShareUserPassword","$vmLocalAdminPass")

if (!(Get-AzureRmResourceGroup -ResourceGroupName $rg_paas -ErrorAction SilentlyContinue))
{
    $RG = New-AzureRmResourceGroup -Name $rg_paas -Location local
} else {
    $RG = Get-AzureRmResourceGroup -ResourceGroupName $rg_paas -ErrorAction SilentlyContinue
}

New-AzureRmResourceGroupDeployment `
    -Name "$($fs_hostname)_deployment" `
    -ResourceGroupName $RG.ResourceGroupName `
    -TemplateUri https://raw.githubusercontent.com/Azure/AzureStack-QuickStart-Templates/master/appservice-fileserver-standalone/azuredeploy.json `
    -TemplateParameterObject $FSParameters `
    -Verbose 
