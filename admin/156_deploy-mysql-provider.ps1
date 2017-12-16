###################################################################################################
# Install the My-SQL Resource Provider in a seperate VM 
###################################################################################################

$domain = "AzureStack"
$prefix = "AzS"
$privilegedEndpoint = "$prefix-ERCS01"
$rppassword = "Passw0rd"

# Set the credentials for the Resource Provider VM
$vmLocalAdminPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("sqlrpadmin", $vmLocalAdminPass) 
$PfxPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 

# Point to the directory where the RP installation files will be stored
$MYSQL_DIR = "D:\Temp\MySQL"
Remove-Item $MYSQL_DIR -Force -Recurse -ErrorAction SilentlyContinue -Confirm:$false
New-Item -ItemType Directory $MYSQL_DIR -Force
push-Location $MYSQL_DIR

$Uri = "https://aka.ms/azurestackmysqlrp"
$MYSQL_RP_URI = (Invoke-WebRequest -UseBasicParsing -MaximumRedirection 0 $Uri -ErrorAction SilentlyContinue).links.href
Start-BitsTransfer $MYSQL_RP_URI
$MYSQL_RP_FILE = Split-Path -Leaf $MYSQL_RP_URI
Start-Process "./$MYSQL_RP_FILE" -ArgumentList "-s" -Wait
$Password = $Global:VMPassword

# Change directory to the folder where you extracted the installation files
# and adjust the endpoints
.\DeployMySQLProvider.ps1 `
  -Azcredential $Global:ServiceAdminCreds `
  -VMLocalCredential $vmLocalAdminCreds `
  -CloudAdminCredential $GLobal:cloudAdminCreds `
  -PrivilegedEndpoint $privilegedEndpoint `
  -DefaultSSLCertificatePassword $PfxPass `
  -DependencyFilesLocalPath .\cert `
  -AcceptLicense 

Pop-Location
