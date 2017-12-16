###################################################################################################
# Install the SQL Resource Provider in a seperate VM 
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
$SQL_DIR = 'D:\TEMP\SQLRP'
Remove-Item $tempDir -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
$Uri = "https://aka.ms/azurestacksqlrp"
$Dir = New-Item -ItemType Directory $SQL_DIR -Force
Set-Location $SQL_DIR

$SQL_RP_URI = (Invoke-WebRequest -UseBasicParsing -MaximumRedirection 0 $Uri -ErrorAction SilentlyContinue).links.href
Start-BitsTransfer $SQL_RP_URI
$SQL_RP_FILE = Split-Path -Leaf $SQL_RP_URI
Start-Process "./$SQL_RP_FILE" -ArgumentList "-s" -Wait

# Change directory to the folder where you extracted the installation files
# and adjust the endpoints
.\DeploySQLProvider.ps1 `
  -AzCredential $Global:ServiceAdminCreds `
  -VMLocalCredential $vmLocalAdminCreds `
  -CloudAdminCredential $Global:cloudAdminCreds `
  -PrivilegedEndpoint $privilegedEndpoint `
  -DefaultSSLCertificatePassword $PfxPass `
  -DependencyFilesLocalPath .\cert
