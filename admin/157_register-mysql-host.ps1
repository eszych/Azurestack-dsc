###################################################################################################
# Register the My-SQL VM as hosting Server in the My-SQL Resource Provider  
###################################################################################################

<#
Hosting Server Name: <SQL Server FQDN or IPv4 of an existing SQL server to be added as a SQL Adapter hosting server>
Port: <Optional parameter for SQL Server Port, default is 1433>
InstanceName: <Optional parameter for SQL Server Instance>
Total Space MB: <The total space in MB to be allocated for creation of databases on the hosting server>
Hosting Server SQL Login Name: <Name of a SQL login to be used for connecting to the SQL database engine on the hosting server using SQL authentication>
Hosting Server SQL Login Password: <Password for the given SQL login>
SKU Name: <Name of the SQL Adapter SKU to associate the hosting server to>

SKU MUST BE CREATED AFTERB SQL RP IS CREATED !!! TAKES UP To 1 Hr to appear

#>

$mysql_hostname = 'mysqlpaas'
$rppassword = "Passw0rd"
$rg_paas = "rg_paas"
$templateuri = 'https://raw.githubusercontent.com/bottkars/AzureStack-QuickStart-Templates/patch-1/101-mysqladapter-add-hosting-server/azuredeploy.json'
$adminusername = "mysqlrpadmin"
$vmLocalAdminPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("mysqlrpadmin", $vmLocalAdminPass) 
$PfxPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 

if (!(Get-AzureRmResourceGroup -ResourceGroupName $rg_paas -ErrorAction SilentlyContinue))
{
    $RG = New-AzureRmResourceGroup -Name $rg_paas -Location local
} else {
    $RG = Get-AzureRmResourceGroup -ResourceGroupName $rg_paas -ErrorAction SilentlyContinue
}

New-AzureRmResourceGroupDeployment `
    -Name "mysqlhost_server" `
    -ResourceGroupName $rg_paasRG `
    -TemplateUri $templateuri `
    -HostingServerName "$($mysql_hostname).local.cloudapp.azurestack.external" `
    -password "$vmlocaladminpass" `
    -username "mysqlrpadmin" `
    -Mode Incremental `
    -totalSpaceMB 102400 `
    -skuName mysql57 `
    -Verbose 