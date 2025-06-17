output "dead_letter_queue_arn" {
  value = { for k, v in module.sqs : k => v.dead_letter_queue_arn }
}

output "dead_letter_queue_id" {
  value = { for k, v in module.sqs : k => v.dead_letter_queue_id }
}

output "dead_letter_queue_name" {
  value = { for k, v in module.sqs : k => v.dead_letter_queue_name }
}

output "dead_letter_queue_url" {
  value = { for k, v in module.sqs : k => v.dead_letter_queue_url }
}

output "queue_arn" {
  value = { for k, v in module.sqs : k => v.queue_arn }
}

output "queue_id" {
  value = { for k, v in module.sqs : k => v.queue_id }
}

output "queue_name" {
  value = { for k, v in module.sqs : k => v.queue_name }
}

output "queue_url" {
  value = { for k, v in module.sqs : k => v.queue_url }
}

