locals {
  iam_items = flatten([
    for role, members in var.bindings : [
      for m in members : {
        role   = role
        member = m
        id     = replace(replace("${role}:${m}", "/", "_"), ":", "_")
      }
    ]
  ])
}