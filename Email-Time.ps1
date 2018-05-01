$fromEmail = ""
$errorEmail = ""
$mailServer = ""
$currTime = get-date -format F
 
Send-MailMessage -From $fromEmail -to $errorEmail  -subject "Email Time" -SmtpServer $mailServer -body "SCRIPT STARTED AT $currTime"