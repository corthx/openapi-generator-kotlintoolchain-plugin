output "username" {
  value       = module.bot.username
  description = "Username of the created service account"
}

output "service_account_id" {
  value       = module.bot.service_account_id
  description = "GitLab user ID of the service account"
}

output "email" {
  value       = module.bot.email
  description = "GitLab-assigned email of the service account, used as Renovate's git author email"
}
