###################################################################################################
# Upload a Windows Server 2016 Image for PAAS Providers -  SQL, MySQL, FileServer, AppService
###################################################################################################

write-host "Windows Server 2016 Image and Gallery Item will be created - please be patient..."

$WIN16EVALISO = "http://care.dlservice.microsoft.com/dl/download/1/4/9/149D5452-9B29-4274-B6B3-5361DBDA30BC/14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO"
$WIN16EVALISODLPATH = "C:\Windows_Server_2016_Eval.iso"

# $ISOPath = $Global:Win2016ISO

if (!(Test-Path $WIN16EVALISODLPATH))
{
    # Write-Warning "$WIN16EVALISODLPATH file does not exist. Please download Windows Server 2016 Eval ISO and restart script..."
    write-host - "Downloading Latest Windows 2016 Server ISO - please be patient..."
    Invoke-WebRequest -Uri $WIN16EVALISO -OutFile $WIN16EVALISODLPATH
    # Break
} else {
    write-host - "Latest Windows 2016 Server ISO has been downloaded - now creating VM Images..."
}


# Import the Connect and ComputeAdmin modules.   
Import-Module "$($GLobal:AZSTools_location)\Connect\AzureStack.Connect.psm1"
Import-Module "$($GLobal:AZSTools_location)\ComputeAdmin\AzureStack.ComputeAdmin.psm1"

New-AzsServer2016VMImage -ISOPath $WIN16EVALISODLPATH -Version Both -CreateGalleryItem:$true -Verbose -IncludeLatestCU 
