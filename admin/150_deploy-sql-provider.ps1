###################################################################################################
# Install the SQL Resource Provider in a seperate VM 
###################################################################################################

$domain = "AzureStack"
$prefix = "AzS"
$privilegedEndpoint = "$prefix-ERCS01"
$rppassword = $Global:VMPassword

# Set the credentials for the Resource Provider VM
$vmLocalAdminPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 
$vmLocalAdminCreds = New-Object System.Management.Automation.PSCredential ("sqlrpadmin", $vmLocalAdminPass) 
$PfxPass = ConvertTo-SecureString "$rppassword" -AsPlainText -Force 

# Point to the directory where the RP installation files will be stored
$SQL_DIR = 'C:\ClusterStorage\Volume1\SQLRP'
Remove-Item $SQL_DIR -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
$Dir = New-Item -ItemType Directory $SQL_DIR -Force
Push-Location $SQL_DIR

$Uri = "https://aka.ms/azurestacksqlrp"
$SQL_RP_URI = (Invoke-WebRequest -UseBasicParsing -MaximumRedirection 0 $Uri -ErrorAction SilentlyContinue).links.href
Start-BitsTransfer $SQL_RP_URI
$SQL_RP_FILE = Split-Path -Leaf $SQL_RP_URI
write-host "Extracting $SQL_RP_FILE to $SQL_DIR"
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

Pop-Location
