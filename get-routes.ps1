
#this script takes a list of computer names and uses WMI to pull any non-broadcast routes, specifying if persistent routes are listed
#author Charles Smith - 6/17/2016
#Instructions for user: configure $csv variable - this variable will take a line separated list of servers in which to probe for routes
#cat output to a file, ex: get-routes.ps1 >> routes.txt
$csv = "C:\Users\charles.smith\Documents\list2.csv"
$outputFile = "C:\Users\charles.smith\Documents\routes2.txt"
$errorFile = "C:\Users\charles.smith\Documents\get-routes-error2.txt"

#clear-content $outputFile
#Clear-Content $errorFile

#
$serverList = Get-Content $csv

write-output "hostname DestinationNetwork Gateway Persistent?[y/n] Interface_IPs" | out-file -append $outputFile  #space seprated values, column headers 

foreach ($server in $serverList){
    #write-output $server | out-file -append $outputFile
       try{
    $hostname = [System.Net.Dns]::GetHostByName($server)
    $IP = [System.Net.Dns]::GetHostAddresses($hostname.HostName)

    #persistent routes set by admins
    $persRoutes = Get-WmiObject -Class Win32_IP4PersistedRouteTable -ComputerName $hostname.HostName| select Destination,NextHop , InterfaceIndex -erroraction Stop #,PSComputerName 
    #non persistent routes set automagically
    $routes = Get-WmiObject -Class win32_IP4RouteTable -ComputerName $hostname.HostName | select Destination, NextHop, InterfaceIndex -erroraction Stop #,PSComputerName #| write-out
    #write-out $routes
    }
    catch{
           #Write-output $server  | out-file -append $errorFile
        Write-output “$($server) Exception Message: $($_.Exception.Message)” | out-file -append $errorFile
        continue
    }
    foreach ($route in $routes){ #gets the non-static routes where the default isn't the next hop
        if ($route.NextHop -ne "0.0.0.0"){
    
        $netIndex = $route.InterfaceIndex #index of network interface route is on, used to populate IPs of network interface
        $IPList = Get-WmiObject win32_networkadapterConfiguration -ComputerName $hostname.HostName | where {$_.InterfaceIndex -eq $netIndex}
        #write-out $IPList.IPAddress
        write-output "$($hostname.HostName),$($route.Destination),$($route.NextHop),N,{$($IPList.IPaddress)}" | out-file -append $outputFile
        }
    }#end of each non persistent route
    foreach ($persRoute in $persRoutes){ # iterates through persistent routes, if any

            write-output "$($hostname.HostName),$($persRoute.Destination),$($persRoute.NextHop),Y,{$($IP.Ipaddresstostring)}" | out-file -append $outputFile
    } #end of each route in persistent routes

}#end foreach server in list