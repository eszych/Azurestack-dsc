<#
.SYNOPSIS
Short description
This script prepares cloudbuilder.vhdx for the use with a multipath attached storage array.

.DESCRIPTION
The Azure Stack Development Kit cloudbuilder.vhdx will be prepared for the use with a multipath 
attached storage array by performing the following steps:

- Add the Multipath I/O feature to the cloudbuilder.vhdx

.EXAMPLE
.\prep-cloudvhd.ps1

.NOTES
This script should be run on the cloudbuilder.vhdx after the asdk-installer.ps1 has been run 
and before the reboot into the cloudbuilder.vhdx.

The Azure Stack Development Kit installer UI script is based on PowerShell and the Windows Presentation Foundation. It is published in this public repository so you can make improvements to it by submitting a pull request.
#>

#requires –runasadministrator

# Get Info on the C:\CloudBuilder.vhdx
$cbvhd = get-vhd C:\CloudBuilder.vhdx

# Check if the vhd is attached...
if ($cbvhd.Attached) {
    #Unmount the cloudbuilder.vhdx
    Dismount-VHD -Path C:\cloudbuilder.vhdx
}

#Installt the Multipath I/O Feature to the cloudbuilder.vhdx
Get-WindowsFeature -Vhd C:\cloudbuilder.vhdx -Name *Multipath* | Install-WindowsFeature -Vhd C:\cloudbuilder.vhdx -IncludeAllSubFeature -IncludeManagementTools -Verbose -Confirm:$false
Get-WindowsFeature -Vhd C:\cloudbuilder.vhdx -Name *Multipath*

# Restart-Computer -Confirm