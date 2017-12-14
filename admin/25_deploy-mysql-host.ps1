# ^[a-z][a-z0-9-]{1,61}[a-z0-9]$

$mysql_hostname = 'mysqlpaas'
$password = "Passw0rd"
$templateuri = 'https://raw.githubusercontent.com/bottkars/AzureStack-QuickStart-Templates/patch-2/mysql-standalone-server-windows/azuredeploy.json'
$vmLocalAdminPass = ConvertTo-SecureString "$password" -AsPlainText -Force 
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("sqlrpadmin", $vmLocalAdminPass) 
$PfxPass = ConvertTo-SecureString "$password" -AsPlainText -Force 

New-AzureRmResourceGroup -Name "rg_$mysql_hostname" -Location local 

New-AzureRmResourceGroupDeployment -Name "$($sql_hostname)_deployment" `    -vmName $mysql_hostname `    -ResourceGroupName "rg_$mysql_hostname" `    -TemplateUri $templateuri `    -adminPassword $vmlocaladminpass `    -adminUsername "sqlrpadmin" `    -windowsOSVersion "2016-Datacenter" `    -Mode Incremental `
    -vmSize Standard_A4 `
    -Verbose 
