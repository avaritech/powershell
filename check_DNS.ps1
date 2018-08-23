#DNS_health_check.ps1
#charles smith, 6/22/2016
#Looks through DNS, attempts to ping each computer name, reports on those that do not respond to pings. Checks for PTR records existing of those that don't respond
#set the following variables:
$domain = ""
$logFile = ""
$dc = ""

#variables instantiating - uncomment variable lines in this section when running the script for the first time *********************

$dns = Get-WmiObject -Class MicrosoftDNS_AType -NameSpace Root\MicrosoftDNS -ComputerName $dc -Filter "DomainName = '$($domain)'"
$rdns = Get-WmiObject -Class MicrosoftDNS_PTRType -NameSpace Root\MicrosoftDNS -ComputerName $dc

#**********************************************************************End of variables instantiating*******************************

#setting up the log file
if (test-path $logFile){ 
    clear-content $logFile
}
write-output "Hostname,IP,PTR_IP[if_exist],PTR_hostname[if_exist],PTR_lookup_info[if_lookup]" | out-File -append $logFile
$outputString = ""

#non-function script code
foreach ($aRecord in $dns) {
    #Write-Output $aRecord.OwnerName #test, comment for prod
    $IP = $aRecord.RecordData #recorddata is the IP address
  
    if(!(test-connection $IP -quiet -count 1)){ #recordData should be the IP address - if can't ping, checks to see if PTR record exists
        #write-host $aRecord.OwnerName "ownername" #FQDN
        $outputString = "$($aRecord.OwnerName)," + "$IP" #starts the output string, which will be going into the line in the csv  
        $split = $IP.Split("{.}")   # tokenizes IP
        $numbers = $split[0], $split[1], $split[2], $split[3]
        [array]::Reverse($numbers) 
        $PI = [string]::Join(".",$numbers)    #should be the PTR IP address
        if($robject = $rdns | Where-Object {$_.OwnerName -eq "${PI}.in-addr.arpa"}){ #this block checks for PTR record in list
            $outputString = $outputString + ","  + "," + $robject.OwnerName + "," + $robject.recorddata
            write-Host $outputString "outputstring when PTR found"
            }
            elseif($robjectName = $rdns | Where-Object {$_.RecordData -eq "$($aRecord.OwnerName)."}){ #This block checks for PTR record with matching hostname (different IP)
                $outputString = $outputString + "," + "," + $robjectName.OwnerName + "," + $robjectName.recorddata
                write-host $outputString "outputString when PTR Hostname Found w/different IP"
            }else{
            #lse no PTR record, just failed
            }
    }#end of checking connection
   
    if($outputString) {write-output $outputString | out-File -append $logFile}
    $outputString = "" 
    #'' next!
    
}#end of iteration through each record
