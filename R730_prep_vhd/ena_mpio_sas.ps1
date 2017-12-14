    Enable-MSDSMAutomaticClaim -Bustype iSCSI -Confirm:$False
    Enable-MSDSMAutomaticClaim -Bustype SAS -Confirm:$False

    Restart-Computer -Confirm:$False