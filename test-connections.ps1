#tests a list of servers either through a tcpclient connection or test-netconnection if the module is installed
#charles smith 7/24/2019

$testPort = "80"
$servers = "www.fehuit.com"




Function TCPConnect($serverList, $port){
    foreach($server in $serverList){
        $tcpConnection = New-Object System.Net.Sockets.TcpClient($server, $port)
        write-host $tcpConnection.Connected
        $tcpConnection.close()

    }
}
Function tnc($serverList, $port){
    foreach($server in $serverList){
        $tncConnection = test-netconnection -computername $server -port $port
    }
}


try{test-netconnection localhost
    #write-host "succeeded" #test-netconnection module installed 
    tnc $servers $testPort
}
catch{
    #write-host "failed" #test-netconnection module not instsalled
    tcpConnect $servers $testPort
}


