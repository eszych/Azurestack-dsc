###################################################################################################
# Upload a Windows Server 2016 Image for PAAS Providers -  SQL, MySQL, FileServer, AppService
###################################################################################################
clear-host
write-host "Windows Server 2016 Image and Gallery Item will be created - please be patient..."

$ISOPath = 'D:\AzureStack_Installer\en_windows_server_2016_x64_dvd_9718492.iso'
if (!(Test-Path $ISOPath))
{
    Write-Warning "$ISOPath file does not exist. Please download Windows Server 2016 Eval ISO and restart script..."
    Break
}
New-AzsServer2016VMImage -ISOPath $ISOPath -Version Both -CreateGalleryItem:$true -Verbose -IncludeLatestCU 
