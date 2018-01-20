###################################################################################################
# Add an Ubuntu 16.04.3-LTS Image 
###################################################################################################

write-host "Ubuntu 16.04.3-LTS Image and Gallery Item will be created - please be patient..."

$OSdiskPath = $Global:UBUNTUVHD
if (!(Test-Path $OSdiskPath))
{
    Write-Warning "$OSdiskPath file does not exist. Please download Ubunut 16.04.3-LTS from Canonical and restart script..."
    Break
}

Add-AzsVMImage `
    -publisher "Canonical" `
    -offer "UbuntuServer" `
    -sku "16.04.3-LTS" `
    -version "1.0.0" `
    -osType Linux `
    -osDiskLocalPath $OSdiskPath `
    -CreateGalleryItem $false 

if (!(Get-AzureRmResourceGroup -ResourceGroupName tenantartifacts -ErrorAction SilentlyContinue))
{
    $RG = New-AzureRmResourceGroup -Name tenantartifacts -Location local
} else {
    $RG = Get-AzureRmResourceGroup -ResourceGroupName tenantartifacts -ErrorAction SilentlyContinue
}

$StorageAccount = New-AzureRmStorageAccount -Name tenantartifacts -Type Standard_LRS -ResourceGroupName $RG.Resourcegroupname -Location local

if (!(Get-AzureStorageContainer -name gallery -Context $StorageAccount.Context -ErrorAction SilentlyContinue))
{
    $GalleryContainer = New-AzureStorageContainer -Name gallery -Permission Blob -Context $StorageAccount.Context
} else {
    $GalleryContainer = Get-AzureStorageContainer -name gallery -Context $StorageAccount.Context -ErrorAction SilentlyContinue
}

Invoke-WebRequest "https://raw.githubusercontent.com/Microsoft/PartsUnlimitedMRP/master/deploy/azurestack/instances/ubuntu_server_1604_base/Canonical.UbuntuServer.1.0.0.azpkg" -OutFile "C:\ClusterStorage\Volume1\Canonical.UbuntuServer.1.0.0.azpkg"

$GalleryContainer | Set-AzureStorageBlobContent -File "C:\ClusterStorage\Volume1\Canonical.UbuntuServer.1.0.0.azpkg" -Verbose
$GalleryItemURI = (Get-AzureStorageBlob -Context $StorageAccount.Context -Blob "Canonical.UbuntuServer.1.0.0.azpkg" -Container 'gallery').ICloudBlob.uri.AbsoluteUri
Add-AzsGalleryItem -GalleryItemUri $GalleryItemURI -Verbose 
