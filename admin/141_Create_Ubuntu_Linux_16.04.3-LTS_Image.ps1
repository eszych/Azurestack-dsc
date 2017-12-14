###################################################################################################
# Add an Ubuntu 16.04.3-LTS Image 
###################################################################################################

write-host "Ubuntu 16.04.3-LTS Image and Gallery Item will be created - please be patient..."

$OSdiskPath = 'D:\AzureStack_Installer\xenial-server-cloudimg-amd64-disk1.vhd'
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

$RG = New-AzureRmResourceGroup -Name tenantartifacts -Location local
$StorageAccount = New-AzureRmStorageAccount -Name tenantartifacts -Type Standard_LRS -ResourceGroupName $RG.Resourcegroupname -Location local

$GalleryContainer = New-AzureStoragseContainer -Name gallery -Permission Blob -Context $StorageAccount.Context
$GalleryContainer | Set-AzureStorageBlobContent -File "D:\AzureStack_Installer\Canonical.UbuntuServer.1.0.0.azpkg" -Verbose
$GalleryItemURI = (Get-AzureStorageBlob -Context $StorageAccount.Context -Blob "Canonical.UbuntuServer.1.0.0.azpkg" -Container 'gallery').ICloudBlob.uri.AbsoluteUri
Add-AzsGalleryItem -GalleryItemUri $GalleryItemURI -Verbose 
