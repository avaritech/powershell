#pinglog.ps1
#1/18/2016, csmith@advocare.com
#pings an IP roughly every second and logs it to a logfile

$ip = "4.2.2.1"
$logFile = "C:\users\csmith\Documents\working\pingOutput.txt"

while($true){
    $time = get-date | select DateTime
    $timeStr = $time.DateTime -replace " ","" -replace "2017","" #no comma between year and time so deleted year

    #$timeStr
    $pingRes = ping -n 1 $ip
    $pingSplit = $pingRes.Split()
    #write-host $pingSplit
    if ($pingSplit[8] -eq "Reply"){$pingStr = $pingSplit[12]}
        else{$pingStr = "Failed"}

    add-content $logFile "$timeStr,$pingStr"
    write-host "$timeStr,$pingStr"
    start-sleep 1
} 
