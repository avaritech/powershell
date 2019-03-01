#will check for specific header
#note - dependent on DNS query
#Charles Smith
$sites = @("") #input the list of sites to check
$ips = @("")
$hostheader = ""
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
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Function MultiSite(){
    while($true){

        foreach($site in $sites){
            $headers = Invoke-WebRequest $site | select Headers
            #$headers.Headers.Keys 
            #$headers.Headers.Values


            if($headers.Headers["Strict-Transport-Security"]){
                write-host $site ":"
                    write-host "`tStrict-Transport-Security header found, value " $headers.Headers["Strict-Transport-Security"] -ForegroundColor Green
                }
                else{
                write-host $site ":"
                write-host "`tStrict-Transport-Security header not found "  -ForegroundColor RED
    
                }
        }
        start-sleep 5
    }
}

Function MultiIPs(){

    while($true){

            foreach($IP in $IPs){
                $headers = Invoke-WebRequest https://$IP/adfs/ls -Headers @{ host=$hostheader } | select Headers
                #$headers.Headers.Keys 
                #$headers.Headers.Values


                if($headers.Headers["Strict-Transport-Security"]){
                    write-host $IP ":"
                        write-host "`tStrict-Transport-Security header found, value " $headers.Headers["Strict-Transport-Security"] -ForegroundColor Green
                    }
                    else{
                    write-host $IP ":"
                    write-host "`tStrict-Transport-Security header not found "  -ForegroundColor RED
    
                    }
            }
            start-sleep 5
        }

}

MultiIPs
MultiSite #comment out the function you don't want to run. Will run multiIPs by default