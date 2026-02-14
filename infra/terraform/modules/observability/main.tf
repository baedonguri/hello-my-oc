resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name          = "${var.project_name}-${var.environment}-status-check-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "EC2 instance status check failed."
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.instance_id
  }

  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "EC2 average CPU is high for 15 minutes."
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.instance_id
  }

  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "cpu_credit_low" {
  count = var.enable_cpu_credit_alarm ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-cpu-credit-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_credit_low_threshold
  alarm_description   = "Burstable CPU credits are low."
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.instance_id
  }

  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []
}
