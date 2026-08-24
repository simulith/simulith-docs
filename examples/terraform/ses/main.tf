# SES identity + OTP template — production ses/ root pattern (generic demoapp).

resource "aws_ses_email_identity" "from" {
  email = var.from_email
}

resource "aws_ses_template" "otp_redemption" {
  name    = local.template_name_otp
  subject = "Your verification code - Demo App"

  html = <<-EOT
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Verification code</title></head>
<body style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
  <h2>Demo App</h2>
  <p>Your verification code is:</p>
  <p style="font-size: 24px; font-weight: bold; letter-spacing: 2px;">{{otpCode}}</p>
  <p style="color: #666; font-size: 14px;">This code expires in 10 minutes.</p>
</body>
</html>
EOT

  text = <<-EOT
Demo App - Verification code

Your verification code is: {{otpCode}}

This code expires in 10 minutes.
EOT
}
