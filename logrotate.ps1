#LogRotate.ps1
#4/24/2018
#Charles Smith 
$logDir = "F:\Logs\www.advocare.com\webrequests"
cd "F:\Logs\www.advocare.com\webrequests"
$files = Get-ChildItem 
#| select LastWrite
$Vacation = (get-date).AddDays(-14)
$files | where{$_.LastWriteTime -lt $Vacation} | ? {compress-archive -path $_ -DestinationPath $logDir\$_.zip
Remove-Item -path $logDir\$_}
 
 
 
#$files |select -first 10 | Compress-Archive -DestinationPath C:\Users\Administrator\Desktop\zips\file.zip
#$files | select -first 10 | ? {Compress-Archive -Path $_ -DestinationPath C:\Users\Administrator\Desktop\zips\$_.zip} 
