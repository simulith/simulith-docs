# SES identity + template — green path on Simulith (SML-172).

resource "aws_ses_email_identity" "otp" {
  email = var.email_identity
}

resource "aws_ses_template" "otp" {
  name    = var.template_name
  subject = "Your code {{code}}"
  html    = "<p>Your code is <strong>{{code}}</strong></p>"
  text    = "Your code is {{code}}"
}
