#will check for specific header
#note - dependent on DNS query
#Charles Smith
$sites= @("") #input the list of sites to check

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