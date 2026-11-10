output "board_ids" {
  value       = module.boards.board_ids
  description = "Map of board name to its GitLab ID"
}
