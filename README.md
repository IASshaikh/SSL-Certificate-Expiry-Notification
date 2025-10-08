
# SSL Certificate Expiry Notifier (PowerShell)

This script checks SSL certificate expiry dates for given websites and sends email alerts
when they are close to expiring.

---

## 🚀 How to Use

1. Clone or download this repository.
2. Open PowerShell and navigate to the script folder.
3. Set your SMTP credentials and recipients securely (do **not** edit the script).

### Option 1 — Environment Variables
```powershell
$env:SMTP_SERVER   = "smtp.office.com"
$env:SMTP_USERNAME = "alerts@yourdomain.com"
$env:SMTP_PASSWORD = "StrongPassword!"
$env:SMTP_FROM     = "alerts@yourdomain.com"
$env:SMTP_TO       = "team@yourdomain.com"

