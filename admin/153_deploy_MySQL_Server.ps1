###################################################################################################
# Create MySQL Hosting Server 
###################################################################################################

write-host "MySQL Hosting Server for PAAS DB will be created - please be patient..."

$mysql_hostname = 'mysqlpaas'
$rg_paas = "rg_paas"
$password = $Global:VMPassword
$templateuri = 'https://raw.githubusercontent.com/bottkars/AzureStack-QuickStart-Templates/patch-2/mysql-standalone-server-windows/azuredeploy.json'
$vmLocalAdminPass = ConvertTo-SecureString "$password" -AsPlainText -Force 
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("sqlrpadmin", $vmLocalAdminPass) 

$MySQLParameters = @{
    "vmName" = "$mysql_hostname"
    "vmTimeZone" = "Pacific Standard Time"
    "vmSize" = "Standard_A3"
    "windowsOSVersion"= "2016-Datacenter"
    "adminUsername" = "mysqlrpadmin"
    "adminPassword" = "$vmLocalAdminPass"
    "mySqlServicePort" = 3306
    "mySqlVersion" = "5.7"
}

if (!(Get-AzureRmResourceGroup -ResourceGroupName $rg_paas -ErrorAction SilentlyContinue))
{
    $RG = New-AzureRmResourceGroup -Name $rg_paas -Location local
} else {
    $RG = Get-AzureRmResourceGroup -ResourceGroupName $rg_paas -ErrorAction SilentlyContinue
}

New-AzureRmResourceGroupDeployment `
    -Name "$($sql_hostname)_deployment" `
    -ResourceGroupName $RG.Resourcegroupname `
    -TemplateUri $templateuri `
    -TemplateParameterObject $MySQLParameters `
    -Mode Incremental `
    -Verbose 
