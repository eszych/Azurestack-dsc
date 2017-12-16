###################################################################################################
# Register the SQL VM as hosting Server in the SQL Resource Provider  
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

$sql_hostname = 'sqlpaas'
$rppassword = "Passw0rd"
$rg_paas = "rg_paas"
$templateuri = 'https://raw.githubusercontent.com/bottkars/AzureStack-QuickStart-Templates/patch-3/101-sqladapter-add-hosting-server/azuredeploy.json'
$adminusername = "sa"
$vmLocalAdminPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("sqlrpadmin", $vmLocalAdminPass) 
$PfxPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 

if (!(Get-AzureRmResourceGroup -ResourceGroupName $rg_paas -ErrorAction SilentlyContinue))
{
    $RG = New-AzureRmResourceGroup -Name $rg_paas -Location local
} else {
    $RG = Get-AzureRmResourceGroup -ResourceGroupName $rg_paas -ErrorAction SilentlyContinue
}

New-AzureRmResourceGroupDeployment `
    -Name "sqlhost_server" `
    -ResourceGroupName $rg_paas `
    -TemplateUri $templateuri `
    -HostingServerName "$($sql_hostname).local.cloudapp.azurestack.external" `
    -hostingServerSQLLoginName "$adminusername" `
    -hostingServerSQLLoginPassword $vmlocaladminpass `
    -Mode Incremental `
    -totalSpaceMB 102400 `
    -skuName SQL2014 `
    -Verbose