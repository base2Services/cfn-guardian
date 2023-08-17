module CfnGuardian::Resource
    class Acm < Base

    def default_alarms    
        alarm = CfnGuardian::Models::AcmAlarm.new(@resource)
        alarm.name = 'CertificateExpiry'
        alarm.metric_name = 'DaysToExpiry'
        alarm.statistic = 'Average'
        alarm.threshold = 5
        alarm.evaluation_periods = 2
        @alarms.push(alarm)
        end

      def default_event_subscriptions()
        event_subscription = CfnGuardian::Models::AcmEventSubscription.new(@resource)
        event_subscription.name = 'AcmCertificateExpired'
        event_subscription.detail_type = 'ACM Certificate Expired'
        @event_subscriptions.push(event_subscription)
      end
    end
  end