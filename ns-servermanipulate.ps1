#VERSION 1.3
#Trey Smith
#trey@avari.tech
#ns-serverManipulate -env [development|production] -server [server] -action [ENABLE|DISABLE]
#FIXME:
#CHECK THAT EVERYTHING IS UP OR DOWN BEFORE CALLING IT A DAY
#POSSIBLY DO IT VIA SERVICE VS SERVER
#MAKE SURE SERVERS SERVICES BELONG TO THE VIP THAT YOU'RE CHECKING


 param (
 [string]$env = "development",
 [string]$server,
 [string]$action
 )


 ##################CONFIGURE PRIOR TO PROD####################
 $errorEmail = ""


 $mailServer = ""
 #$action = "enable"
 $fromEmail = ""
 $environment = $env.ToString()
##############################################################
#ERROR CHECKING
if ($action -ne "enable" -and $action -ne "disable"){
    write-host "INCORRECTION ACTION, must be enable or disable. format ns-serverManipulate -env [development|production] -server [server] -action [ENABLE|DISABLE]"
    exit
}
if ($environment -ne "production" -and $environment -ne "development"){
    write-host "INCORRECTION ACTION, must be development or production. format ns-serverManipulate -env [development|production] -server [server] -action [ENABLE|DISABLE]"
    exit
}
$currTime = get-date -format F


 #FIXME: check for active netscaler
 #ENVIRONMENT SPECIFIC###### UPDATE FOR BOTH ENVIRONMNETS!!!!!!!
 if ($environment -eq "development"){
     $hostname = "" 
     $username = "" #dev
     $password = "" #dev
     
     $VIP_HTTP = "VIP_web_http_DR" #VIP name for HTTP (DEV)
     $VIP_HTTPS = "VIP_web_https_DR" #VIP name for HTTPS (Prod)
 }


 #fixme FIX THE WHOLE PROD SECTION###################
  if ($environment -eq "production"){
     $hostname = "" 
     $username = "nsautomation" #dev
     $password = "" #dev
    
     $VIP_HTTP = "VIP_web_http_DR" #VIP name for HTTP (DEV)
     $VIP_HTTPS = "VIP_web_https_DR" #VIP name for HTTPS (Prod)
 }
 #fixme FIX THE WHOLE PROD SECTION###################




 $warmupURLS = "https://$server.com/",`
    "https://$server.com/store"
$warmupTimes = @("URL,Total Seconds `n")


Send-MailMessage -From $fromEmail -to $errorEmail  -subject "AUTO-SERVER SCRIPT STARTING RUNNING" -SmtpServer $mailServer -body "(THIS EMAIL IS FROM THE AUTOMATED SCRIPT) ARGUMENTS are $action $environment $server`n CURRENT TIME IS $currTime"
 
 #fixme set enable or disable arguments to call whichever function
 #$response = ""#fixme delete this later for parsing


# Ignore Cert Errors
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true } #from Carl, but for some reason, this appears to be what it takes:
###############################TRUST ALL CERTS###################################
add-type @"

    using System.Net;

    using System.Security.Cryptography.X509Certificates;

    public class TrustAllCertsPolicy : ICertificatePolicy {

        public bool CheckValidationResult(

            ServicePoint srvPoint, X509Certificate certificate,

            WebRequest request, int certificateProblem) {

            return true;

        }

    }

"@

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#################################################################################

#FUNCTIONS ARE CALLED AT THE BOTTOM OF THE SCRIPT#################################
function Login {

    # Login to NetScaler and save session to global variable

    $body = ConvertTo-JSON @{

        "login"=@{

            "username"="$username";

            "password"="$password"

            }

        }
    
        try{Invoke-RestMethod -uri "$hostname/nitro/v1/config/login" -body $body -SessionVariable NSSession -ContentType "application/vnd.com.citrix.netscaler.login+json" -Method POST}
        catch{#write-host "invoke-restmethod failed to $hostname $VIP_HTTP error message is $_"; 
                HandleError("error connecting to Netscaler invoke-restmethod failed to $hostname $VIP_HTTP error message is $_")
            }


    $Script:NSSession = $local:NSSession

}

function Enable {

# disable server

    $body = ConvertTo-JSON @{
    "server"=@{
        "name"=$server
        
        }
    }
   # $body
   try{Invoke-RestMethod -uri "$hostname/nitro/v1/config/server?action=enable" -body $body -WebSession $NSSession -ContentType "application/json" -Method POST}
   catch{#write-host "invoke-restmethod failed to $hostname $VIP_HTTP error message is $_"; 
            HandleError("error connecting to Netscaler invoke-restmethod failed to $hostname $VIP_HTTP error message is $_")
        }

  
} #fixme: add error cehcking for anything other than 200

function Disable {

# disable server

    $body = ConvertTo-JSON @{
    "server"=@{
        "name"=$server;
        "graceful"="YES"
        }
    }
   # $body
   try{Invoke-RestMethod -uri "$hostname/nitro/v1/config/server?action=disable" -body $body -WebSession $NSSession -ContentType "application/json" -Method POST}
   catch{#write-host "invoke-restmethod failed to $hostname $VIP_HTTP error message is $_"; 
            HandleError("error connecting to Netscaler invoke-restmethod failed to $hostname $VIP_HTTP error message is $_")
        }
    #Invoke-RestMethod -uri "$hostname/nitro/v1/config/login" -body $body -SessionVariable NSSession -ContentType "application/vnd.com.citrix.netscaler.logout+json" -Method POST

    #$Script:NSSession = $local:NSSession
} #fixme: add error cehcking for anything other than 200

function Logout {

# Logout

    $body = ConvertTo-JSON @{
    "logout"=@{}
    }
   # $body
   try{Invoke-RestMethod -uri "$hostname/nitro/v1/config/logout" -body $body -WebSession $NSSession -ContentType "application/vnd.com.citrix.netscaler.logout+json" -Method POST}
   catch{#write-host "invoke-restmethod failed to $hostname $VIP_HTTP error message is $_"; 
            Send-MailMessage -From $fromEmail -to $errorEmail  -subject "AUTO-SERVER REMOVAL SCRIPT FAILED" -SmtpServer $mailServer -body "LOGOUT FAILED"
            exit
        }
    if ($action -eq "disable"){
        Send-MailMessage -From $fromEmail -to $errorEmail  -subject "AUTO-SERVER SCRIPT COMPLETED SUCCESSFULLY" -SmtpServer $mailServer -body "ARGUMENTS are $action $environment $server `n CURRENT TIME IS $currTime"
    }
    if ($action -eq "enable"){
        Send-MailMessage -From $fromEmail -to $errorEmail  -subject "AUTO-SERVER SCRIPT COMPLETED SUCCESSFULLY" -SmtpServer $mailServer -body "ARGUMENTS are $action $environment $server `n URL RESULTS ARE $warmupTimes CURRENT TIME IS $currTime"
        
    }
    $Script:NSSession = $local:NSSession
}

function SanityCheck{
    #fixme: see if actually disabled first. 
    #fixme: See if exist in VIP
   try{$response = Invoke-RestMethod -uri "$hostname/nitro/v1/config/lbvserver/$VIP_HTTPS" -WebSession $NSSession -ContentType "application/vnd.com.citrix.lbvserver_list+json" -Method GET}
   catch{#write-host "invoke-restmethod failed to $hostname $VIP_HTTP error message is $_"; 
            HandleError("error connecting to Netscaler invoke-restmethod failed to $hostname $VIP_HTTP error message is $_")
        }#$response.lbvserver

   $activeServices = $response.lbvserver.activeservices
   $totalservices = $response.lbvserver.totalservices
   #$activeServices;$totalservices
   
    if ($totalservices -gt $activeServices){HandleError("ONE OR MORE SERVERS ARE ALREADY DISABLED - $VIP_HTTPS VIP")}
        #get servers in VIP
        #if any disabled, stop, throw error or email! Exit script
        try{$response = Invoke-RestMethod -uri "$hostname/nitro/v1/config/lbvserver/$VIP_HTTP" -WebSession $NSSession -ContentType "application/vnd.com.citrix.lbvserver_list+json" -Method GET}
        catch{#write-host "invoke-restmethod failed to $hostname $VIP_HTTP error message is $_"; 
            HandleError("error connecting to Netscaler invoke-restmethod failed to $hostname $VIP_HTTP error message is $_")
        }
        $activeServices = $response.lbvserver.activeservices
        $totalservices = $response.lbvserver.totalservices
   
   if ($totalservices -gt $activeServices){HandleError("ONE OR MORE SERVERS ARE ALREADY DISABLED")}
}
function Warmup{

    foreach ($url in $warmupURLS){#Invoke-WebRequest -URI $url -method GET
        try{start-sleep 1
        write-host $url
        #$bytes = [system.Text.Encoding]::UTF8.GetBytes("key=value")
        #$web = [net.WebRequest]::Create("$url") -as [net.HttpWebRequest]
        #$web.ContentType = "application/x-www-form-urlencoded"
        #$web.Host
        #$web.Method = "GET"
        #$stream = $web.GetResponse()
        #$stream
        #$stream
        #$result = Invoke-WebRequest -URI $url -Method GET -TimeoutSec 200 #PREVIOUS WORKING (6/7)
        $result = measure-command{Invoke-WebRequest -URI $url -Method GET -TimeoutSec 200}

        $script:warmupTimes += "$url," + $result.TotalSeconds.ToString() + "`n"
        
        }catch{HandleError("ERROR WITH WARMUP ON $server")} #catch[TIMEOUT ERROR]{} or can try -timeoutsec and set very high
        #catch{}# TRY AGAIN AND IF FAIL THEN THEN GO ON
    #$stream.Write($bytes,0,$bytes.Length)

    #$stream.ToString()
    
    
    } #FIXME put all 5, timeout, retries, fail and email on failure
}
function HandleError($description){
    $dateTime = Get-Date
    write-Host "SCRIPT STOPPING DUE TO $description"
       Send-MailMessage -From $fromEmail -to $errorEmail  -subject "AUTO-SERVER REMOVAL SCRIPT FAILED" -SmtpServer $mailServer -body "$environment $description $dateTime CURRENT TIME IS $currTime"
   Logout
   exit

}

#BEGIN CALLING FUNCTIONS. 
Login
if ($action -eq "disable"){
    SanityCheck #check to make sure no disabled servers
    Disable #disable the server
}
if ($action -eq "enable"){
    #check if actually disabled fixme    
    Warmup
    start-sleep 1
    Enable

    }

Logout