output "email_identity" {
  value = aws_ses_email_identity.otp.email
}

output "template_name" {
  value = aws_ses_template.otp.name
}
