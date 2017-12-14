Invoke-Webrequest https://go.microsoft.com/fwlink/?LinkID=623230 -OutFile C:\VSCode.exe
Start-Process -FilePath C:\VSCode.exe -ArgumentList '/VerySilent /mergetasks="addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath,!runcode"'
Start-Sleep -S 240
# Restart-Computer -Force -Confirm:$false
