###################################################################################################
# Install the PowerShell Tools and login to the Azure Stack Environment
###################################################################################################

write-host "PowerShell Script for Azure Stack will be installed"

# Disable Windows Update
Start-Process "sc" -ArgumentList "config wuauserv start=disabled" -Wait -NoNewWindow

# Set the PS Repo
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Install some Tools "install-gitscm"
if (!$noutils.IsPresent)
{
    $Utils = ("install-chrome","install-gitscm","Install-VSCode","Create-AZSportalsshortcuts")
    foreach ($Util in $Utils)
    {
        Install-Script $Util -Scope CurrentUser -Force -Confirm:$false
        ."$util.ps1"
    }
}

# Uninstall any existing Azure PowerShell modules. To uninstall, close all the active PowerShell sessions, and then run the following command:
Get-Module -ListAvailable | where-Object {$_.Name -like "Azure*"} | Uninstall-Module -ErrorAction SilentlyContinue

# Install PowerShell for Azure Stack.
Install-Module -Name AzureRm.BootStrapper -Force

Use-AzureRmProfile -Profile $Global:AzureRmProfile -Force

Install-Module -Name AzureStack -RequiredVersion $Global:AzureStackModuleVersion -Force 

git clone https://github.com/Azure/AzureStack-Tools/  $Global:AZSTools_location
