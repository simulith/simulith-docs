output "from_email" {
  description = "Verified sender email (parameters/ remote state)."
  value       = aws_ses_email_identity.from.email
}

output "otp_template_name" {
  description = "OTP template name (parameters/ remote state)."
  value       = aws_ses_template.otp_redemption.name
}

output "from_email_identity_arn" {
  description = "SES identity ARN."
  value       = aws_ses_email_identity.from.arn
}
