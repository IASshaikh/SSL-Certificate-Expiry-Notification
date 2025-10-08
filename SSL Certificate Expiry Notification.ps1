
# SECURITY: This public example intentionally leaves SMTP fields blank.
# Do NOT fill credentials here in the repo. Use one of:
#  - environment variables (SMTP_USERNAME, SMTP_PASSWORD, SMTP_FROM, SMTP_TO)
#  - PowerShell SecretManagement or OS credential store
#  - CI/CD secrets (GitHub Actions Secrets)
# NOTE: If a hostname includes "https://", TcpClient may fail — use only the host (example.com) when running.



# Define variables

# Websites array with individual threshold days
$websites = @(
    @{ 'hostname' = 'erimranblog.wordpress.com'; 'thresholdDays' = 15 },
    @{ 'hostname' = 'xyz.com'; 'thresholdDays' = 15 }
   )

# SMTP Configuration
$smtpServer = "smtp.office.com"
$smtpFrom = ""
$smtpTo = ""
$smtpCC = ""
#$smtpCC = ""
$smtpSubject = "SSL Certificate Expiry Notification"
$smtpUsername = ""
$smtpPassword = ""

# Loop through each website
foreach ($site in $websites) {
    $hostname = $site.hostname
    $thresholdDays = $site.thresholdDays

    try {
        Write-Host "Checking SSL certificate for $hostname"

        # Create TCP client and connect to the server
        $tcpClient = New-Object Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($hostname, 443, $null, $null)
        $waitSuccess = $asyncResult.AsyncWaitHandle.WaitOne(15000, $false)  # 15 seconds timeout
        if (-not $waitSuccess) {
            throw "Connection to $hostname on port 443 timed out."
        }
        $tcpClient.EndConnect($asyncResult)

        # Create SSL stream with custom validation callback
        $sslStream = New-Object Net.Security.SslStream($tcpClient.GetStream(), $false, {
            param ($sender, $certificate, $chain, $sslPolicyErrors)
            # Uncomment the following line to bypass certificate errors (not recommended for production)
            # return $true

            # Validate certificate (recommended)
            if ($sslPolicyErrors -eq [System.Net.Security.SslPolicyErrors]::None) {
                return $true
            } else {
                Write-Error "Certificate error for ${hostname}: $sslPolicyErrors"
                return $false
            }
        })

        # Specify SSL/TLS protocols
        $sslProtocols = [System.Security.Authentication.SslProtocols]::Tls12

        # Authenticate as client
        $sslStream.AuthenticateAsClient($hostname, $null, $sslProtocols, $false)

        # Get the certificate
        $cert = $sslStream.RemoteCertificate
        if ($cert -eq $null) {
            throw "Unable to retrieve SSL certificate from $hostname"
        }

        $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cert)
        $expiryDate = $cert2.NotAfter
        $daysToExpire = ($expiryDate - (Get-Date)).Days

        Write-Host "Certificate for $hostname expires on $expiryDate, which is in $daysToExpire days"

        # Close connections
        $sslStream.Close()
        $tcpClient.Close()

        # Check if the certificate is within the threshold
        if ($daysToExpire -le $thresholdDays) {
            # Prepare email body with enhanced HTML formatting

$emailBody = @"

<html>
<head>
    <style>
        .highlight { font-weight: bold; }
    </style>
</head>

Hello Team,

<p>The SSL certificate for <a href='https://$hostname'>https://$hostname</a> will expire in <span class='highlight'>$daysToExpire days</span> on <b>$expiryDate</b>.</p>
<br>
---------------------------------------------<br>
Regards,<br>
Imran Shaikh<br>
---------------------------------------------<br>
</body>
</html>
"@

<#
            $emailBody = @"
<html>
<head>
    <style>
        .highlight { font-weight: bold; }
    </style>
</head>
<body>
    <p>The SSL certificate for <a href='https://$hostname'>https://$hostname</a> will expire in <span class='highlight'>$daysToExpire days</span> on <b>$expiryDate</b>.</p>
    <br>
---------------------------------------------
Regards,
Automations Team
---------------------------------------------
</body>
</html>
"@

#>

            # Send email
            try {
                Write-Host "Preparing email notification for $hostname"
                $mailMessage = New-Object system.net.mail.mailmessage
                $mailMessage.From = $smtpFrom

                # Add 'To' recipients
                $smtpTo.Split(",") | ForEach-Object {
                    $toEmail = $_.Trim()
                    if ($toEmail -ne "") {
                        $mailMessage.To.Add($toEmail)
                    }
                }

                # Add 'CC' recipients
                if ($smtpCC -ne "") {
                    $smtpCC.Split(",") | ForEach-Object {
                        $ccEmail = $_.Trim()
                        if ($ccEmail -ne "") {
                            $mailMessage.CC.Add($ccEmail)
                        }
                    }
                }

                #$mailMessage.Subject = $smtpSubject
                 # Include hostname in the email subject
                $mailMessage.Subject = "$smtpSubject - $hostname"
                $mailMessage.Body = $emailBody
                $mailMessage.IsBodyHtml = $true  # Enable HTML formatting

                Write-Host "Sending email for $hostname..."
                $smtpClient = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
                $smtpClient.EnableSsl = $true
                $smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $smtpPassword)
                $smtpClient.Timeout = 15000  # 15 seconds timeout
                $smtpClient.Send($mailMessage)
                Write-Host "Email sent successfully for $hostname."
            } catch {
                Write-Error "Error sending email for ${hostname}: $_"
                continue
            }
        } else {
            Write-Host "Certificate for $hostname is valid for more than $thresholdDays days ($daysToExpire days left). No email sent."
        }
    } catch {
        Write-Error "Error retrieving SSL certificate for ${hostname}: $_"
        continue
    }
}

# End of script
