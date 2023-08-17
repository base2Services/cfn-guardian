module CfnGuardian::Resource
    class Acm < Base

    def default_alarms    
        alarm = CfnGuardian::Models::AcmAlarm.new(@resource)
        alarm.name = 'CertificateExpiry'
        alarm.metric_name = 'DaysToExpiry'
        alarm.statistic = 'Average'
        alarm.threshold = 30
        alarm.comparison_operator = 'LessThanThreshold'
        alarm.evaluation_periods = 1
        alarm.period = 86400
        @alarms.push(alarm)
        end
        
      def default_event_subscriptions()
        event_subscription = CfnGuardian::Models::AcmEventSubscription.new(@resource)
        event_subscription.name = 'AcmCertificateExpired'
        event_subscription.detail_type = 'ACM Certificate Expired'
        event_subscription.source = 'aws.acm'
        @event_subscriptions.push(event_subscription)

        event_subscription = CfnGuardian::Models::AcmEventSubscription.new(@resource)
        event_subscription.name = 'AcmRenewalActionRequired'
        event_subscription.detail_type = 'ACM Certificate Renewal Action Required'
        event_subscription.source = 'aws.acm'
        @event_subscriptions.push(event_subscription)
      end
    end
  end