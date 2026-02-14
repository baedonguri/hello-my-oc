output "alarm_names" {
  value = compact([
    aws_cloudwatch_metric_alarm.status_check_failed.alarm_name,
    aws_cloudwatch_metric_alarm.cpu_utilization_high.alarm_name,
    try(aws_cloudwatch_metric_alarm.cpu_credit_low[0].alarm_name, null)
  ])
}
