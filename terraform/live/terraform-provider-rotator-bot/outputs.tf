output "username" {
  value       = module.bot.username
  description = "Username of the created service account"
}

output "service_account_id" {
  value       = module.bot.service_account_id
  description = "GitLab user ID of the service account"
}
