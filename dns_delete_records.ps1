#DNS_delete_records.ps1
#charles smith, 6/22/2016
#Looks through DNS, attempts to ping each computer name, reports on those that do not respond to pings. Checks for PTR records existing of those that don't respond
#set the following variables:
$domain = "iacp.dc"
$logFile = "C:\Users\charles.smith\Documents\scripts\workinprogress\DNSrecordResults.txt"
$toDeleteLogFile = "C:\Users\charles.smith\Documents\scripts\workinprogress\DNS_Delete.txt"

$forwardLookupZone = ""


#variables instantiating - uncomment variable lines in this section when running the script for the first time *********************

$dns = Get-WmiObject -Class MicrosoftDNS_AType -NameSpace Root\MicrosoftDNS -ComputerName da1rtdc801  -Filter "DomainName = '$($domain)'"
#$rdns = Get-WmiObject -Class MicrosoftDNS_PTRType -NameSpace Root\MicrosoftDNS -ComputerName da1rtdc801

#**********************************************************************End of variables instantiating*******************************

$recordsToDelete = import-csv $toDeleteLogFile
#$records = Get-WmiObject -Class MicrosoftDNS_AType -NameSpace Root\MicrosoftDNS -ComputerName da1rtdc801
foreach ($record in $recordsToDelete){
    if(!(test-connection $Record.IP -quiet -count 1)){
        write-host $record.Hostname $record.IP
        $dns | where-object {($_.RecordData -eq $Record.IP) -and ($_.OwnerName -eq $record.Hostname)} | Remove-WmiObject 
    #remove-dnsserverresourcerecord -zoneName $forwardLookupZone -RRType "A" -Name $record.Hostname -RecordData $record.IP
    }else{write-host "$Record.hostname PINGED SUCCESSFULLY!!!!"}
}
#$dns | where-object {($_.RecordData -eq "10.1.212.13") -and ($_.OwnerName -eq "computer.domain.root")} | Remove-WmiObject   
#$dns