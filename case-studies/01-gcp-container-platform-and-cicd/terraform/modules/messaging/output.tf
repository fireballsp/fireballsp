output "cloud_tasks_queues_details" {
  value = {
    for name, queue in google_cloud_tasks_queue.queues :
    name => {
      id   = queue.id
      name = queue.name
    }
  }
}