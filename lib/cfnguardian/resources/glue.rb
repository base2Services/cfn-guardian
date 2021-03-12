module CfnGuardian::Resource
  class Glue < Base
    def default_event_subscriptions()
      event_subscription = CfnGuardian::Models::BatchEventSubscription.new(@resource)
      event_subscription.name = 'FailedGlueJob'
      event_subscription.detail_type = 'Glue Job State Change'
      event_subscription.detail = {
        'state': ['FAILED'],
        'jobName': [{'prefix': @resource['Id']}]
      }
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::BatchEventSubscription.new(@resource)
      event_subscription.name = 'TimeoutGlueJob'
      event_subscription.detail_type = 'Glue Job State Change'
      event_subscription.detail = {
        'state': ['TIMEOUT'],
        'jobName': [{'prefix': @resource['Id']}]
      }
      @event_subscriptions.push(event_subscription)
    end
  end
end