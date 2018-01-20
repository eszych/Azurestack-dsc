# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE.txt in the project root for license information.

<#
    .SYNOPSIS
    List all Azure Marketplace Items available for syndication and allows to download them
    Requires an Azure Stack System to be registered for the subscription used to login
#>

###################################################################################################
# Download Items from the Azure Marketplace 
###################################################################################################

write-host "Download Items from the Azure Marketplace "

$Cloud = "AzureCloud"
$Destination = "C:\AzSMarketplace"
$AzureCredentials = $GLOBAL:ServiceAdminCreds

function Set-String {
    param (
           [parameter(mandatory=$true)]
           [long] $size
         )

    if ($size -gt 1073741824) {
        return [string]([math]::Round($size / 1073741824)) + " GB"
    } elseif ($size -gt 1048576) {
        return [string]([math]::Round($size / 1048576)) + " MB"
    } else {return "<1 MB"} 
}

$AzMarketPlaceIDs = ( `
    "Microsoft.CustomScriptExtension-arm", `
    "Microsoft.DSC-arm", `
    "microsoft.antimalware-windows-arm", `
    "microsoft.custom-script-linux-arm", `
    "Microsoft.SQLIaaSExtension", `
    "microsoft.docker-arm" `
)

$vhdDestinationArray = @() 
$azpkgDestinationArray = @()

$azureAccount = Add-AzureRmAccount -Credential $AzureCredentials
$AzureSubscriptionID = $azureAccount.Context.Subscription.Id
$azureEnvironment = Get-AzureRmEnvironment -Name $Cloud
$resources=Get-AzureRmResource
$resource=$resources.resourcename
$registrations=$resource|where-object {$_ -like "AzureStack*"}
$registration = $registrations[0]

# Retrieve the access token
$tokens = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.TokenCache.ReadItems()
$token = $tokens |Where-Object Resource -EQ $azureEnvironment.ActiveDirectoryServiceEndpointResourceId |Where-Object DisplayableId -EQ $azureAccount.Context.Account.Id |Sort-Object ExpiresOn |Select-Object -Last 1

# Retrieve the URL for MArketplace Item
$uri1 = $($azureEnvironment.ResourceManagerUrl.ToString().TrimEnd('/')) + "/subscriptions/"+  $($AzureSubscriptionID.ToString()) + "/resourceGroups/azurestack/providers/Microsoft.AzureStack/registrations/" + $($Registration.ToString()) + "/products?api-version=2016-01-01"
$Headers = @{ 'authorization'="Bearer $($Token.AccessToken)"} 
$products = (Invoke-RestMethod -Method GET -Uri $uri1 -Headers $Headers).value

$Marketitems=foreach ($product in $products)
{
    switch($product.properties.productKind)
    {
        'virtualMachine'
        {
            Write-output ([pscustomobject]@{
                Id        = $product.name.Split('/')[-1]
                Type      = "Virtual Machine"
                Name      = $product.properties.displayName
                Description = $product.properties.description
                Publisher = $product.properties.publisherDisplayName
                Version   = $product.properties.offerVersion
                Size      = Set-String -size $product.properties.payloadLength
            })
        }

        'virtualMachineExtension'
        {
            Write-output ([pscustomobject]@{
                Id        = $product.name.Split('/')[-1]
                Type      = "Virtual Machine Extension"
                Name      = $product.properties.displayName
                Description = $product.properties.description
                Publisher = $product.properties.publisherDisplayName
                Version   = $product.properties.productProperties.version
                Size      = Set-String -size $product.properties.payloadLength
            })
        }

        Default
        {
            Write-Warning "Unknown product kind '$_'"
        }
    }
}

foreach ($AzMarketPlaceID in $AzMarketPlaceIDs){

    write-host $AzMarketPlaceID

    $Marketitems|ForEach-Object{
        $productid=$_.id

        if ($productid -match $AzMarketPlaceID){
            write-host $productid
            # get name of azpkg
            $uri2 = "$($azureEnvironment.ResourceManagerUrl.ToString().TrimEnd('/'))/subscriptions/$($AzureSubscriptionID.ToString())/resourceGroups/azurestack/providers/Microsoft.AzureStack/registrations/$Registration/products/$($productid)?api-version=2016-01-01"
            # Write-Host $URI2
            $Headers = @{ 'authorization'="Bearer $($Token.AccessToken)"} 
            $productDetails = Invoke-RestMethod -Method GET -Uri $uri2 -Headers $Headers
            $azpkgName = $productDetails.properties.galleryItemIdentity

            # get download location for apzkg
            $uri3 = "$($azureEnvironment.ResourceManagerUrl.ToString().TrimEnd('/'))/subscriptions/$($AzureSubscriptionID.ToString())/resourceGroups/azurestack/providers/Microsoft.AzureStack/registrations/$Registration/products/$productid/listDetails?api-version=2016-01-01"
            # Write-Host $uri3
            $downloadDetails = Invoke-RestMethod -Method POST -Uri $uri3 -Headers $Headers

            # download azpkg
            $azpkgsource = $downloadDetails.galleryPackageBlobSasUri
            $FileExists=Test-Path "$destination\$azpkgName.azpkg"
            $DestinationCheck=Test-Path $destination
            If ($DestinationCheck -eq $false){
                new-item -ItemType Directory -force $destination
            }

            If ($FileExists -eq $true) {
                Remove-Item "$destination\$azpkgName.azpkg" -force
            } else {
                New-Item "$destination\$azpkgName.azpkg"
            }
            $azpkgdestination = "$destination\$azpkgName.azpkg"
            $azpkgDestinationArray += $azpkgdestination
            
            Start-BitsTransfer -Description $productid -DisplayName $productid -source $azpkgsource -destination $azpkgdestination -Priority High

            # download vhd
            $vhdName = $productDetails.properties.galleryItemIdentity
            $vhdSource = $downloadDetails.properties.osDiskImage.sourceBlobSasUri
            If (!([string]::IsNullOrEmpty($vhdsource))) {
                $FileExists=Test-Path "$destination\$productid.vhd" 
                If ($FileExists -eq $true) {
                        Remove-Item "$destination\$productid.vhd" -force
                    } else {
                        New-Item "$destination\$productid.vhd" 
                    }
                $vhdDestination = "$destination\$productid.vhd"
                $vhdDestinationArray += $vhdDestination
                Start-BitsTransfer -Description $productid"_vhd" -DisplayName $productid"_vhd" -source $vhdSource -destination $vhdDestination -Priority High
            }
        }
    } 
}


Logout-AzureRmAccount 

# Import Modules to connect to AzS 
write-host "Import Modules to connect to AzS"
Import-Module "$($GLobal:AZSTools_location)\Connect\AzureStack.Connect.psm1" -Force
Import-Module AzureRM.AzureStackStorage -Force
Import-Module "$($Global:AZSTools_location)\serviceAdmin\AzureStack.ServiceAdmin.psm1" -Force
Import-Module "$($Global:AZSTools_location)\ComputeAdmin\AzureStack.ComputeAdmin.psm1" -Force

# For Azure Stack development kit, this value is set to https://adminmanagement.local.azurestack.external. To get this value for Azure Stack integrated systems, contact your service provider.
$ArmEndpoint = "https://adminmanagement.local.azurestack.external"

# For Azure Stack development kit, this value is adminvault.local.azurestack.external 
$KeyvaultDnsSuffix = "adminvault.local.azurestack.external"
$GraphAudience = "https://graph.windows.net/"

# Register an AzureRM environment that targets your Azure Stack instance
Add-AzureRMEnvironment -Name "AzureStackAdmin" -ArmEndpoint $ArmEndpoint
Set-AzureRmEnvironment -Name "AzureStackAdmin" -GraphAudience $GraphAudience

Login-AzureRmAccount -EnvironmentName "AzureStackAdmin" -TenantId $Global:TenantID -Credential $AzureCredentials -ErrorAction Stop

# Get the Active Directory tenantId that is used to deploy Azure Stack
$TenantID = Get-AzsDirectoryTenantId -AADTenantName $TenantName -EnvironmentName "AzureStackAdmin"

foreach ($vhdpath in $vhdDestinationArray){
    Write-Host $vhdpath

#    Add-AzsVMImage `
#        -publisher "Canonical" `
#        -offer "UbuntuServer" `
#        -sku "16.04.3-LTS" `
#        -version "1.0.0" `
#        -osType Linux `
#        -osDiskLocalPath $OSdiskPath `
#        -CreateGalleryItem $false 

}

if (!(Get-AzureRmResourceGroup -ResourceGroupName tenantartifacts -ErrorAction SilentlyContinue))
{
    $RG = New-AzureRmResourceGroup -Name tenantartifacts -Location local
} else {
    $RG = Get-AzureRmResourceGroup -ResourceGroupName tenantartifacts -ErrorAction SilentlyContinue
}

$StorageAccount = New-AzureRmStorageAccount -Name tenantartifacts -Type Standard_LRS -ResourceGroupName $RG.Resourcegroupname -Location local

if (!(Get-AzureStorageContainer -Name gallery -Context $StorageAccount.Context -ErrorAction SilentlyContinue))
{
    $GalleryContainer = New-AzureStorageContainer -Name gallery -Permission Blob -Context $StorageAccount.Context -ErrorAction SilentlyContinue
} else {
    $GalleryContainer = Get-AzureStorageContainer -Name gallery -Context $StorageAccount.Context -ErrorAction SilentlyContinue
}

foreach ($azpkgpath in $azpkgDestinationArray){
    Write-Host $azpkgpath
    $azpkgname = $azpkgpath.Split("\")[2]
    write-host $azpkgname
    $GalleryContainer | Set-AzureStorageBlobContent -File "$azpkgpath" -Verbose -Force
    $GalleryItemURI = (Get-AzureStorageBlob -Context $StorageAccount.Context -Blob $azpkgname -Container 'gallery').ICloudBlob.uri.AbsoluteUri
    Add-AzsGalleryItem -GalleryItemUri $GalleryItemURI -Verbose 
}
