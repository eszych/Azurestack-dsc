# Azurestack-dsc

For R730 Servers with a multipath SAS attached JBOD run  the scripts in the follwing order:
1. prep-cloudvhd.ps1 - run in the base Windows 2016 Install as Administrator
	This will install the Multipath Feature into the CloudBuilder.VHD
2. asdk-installer.ps1 - run in the base Windows 2016 Install as Administrator
	This is the AzureStack Dev Kit Installater that comes from Microsoft.
	Let the Server reboot after the wizzard has finished.
3. ena_mpio_sas.ps1 - run in the AzureStack Env as Administrator
	This will enable the Multipath Settings for SAS.
	Server needs to be rebooted again to enable the multipathing.
4. asdk-installer.ps1  - run in the AzureStack Env as Administrator
	This will finalize the AzS DevKit Installation