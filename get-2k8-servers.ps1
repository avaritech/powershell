$servers = get-content C:\users\charles.smith\Documents\scripts\workinprogress\patcha.txt

foreach ($server in $servers){
    $os = get-wmiobject win32_operatingsystem -computername $server | select Caption #operating system check. This script only needs to run on 2k8 servers
    if ($os.Caption.contains("2008")){write-output $server | out-File -append C:\users\charles.smith\Documents\scripts\code-in-progress\2k8-qa-servers.txt}else{write-host "$server ISNT A 2k8";continue}

    }
