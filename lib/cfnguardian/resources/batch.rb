module CfnGuardian::Resource
  class Batch < Base
    def default_event_subscriptions()
      event_subscription = CfnGuardian::Models::BatchEventSubscription.new(@resource)
      event_subscription.name = 'FailedBatch'
      event_subscription.detail_type = 'Batch Job State Change'
      event_subscription.detail = {
        'status': ['FAILED'],
        'jobQueue': ["arn:aws:batch:${AWS::Region}:${AWS::AccountId}:job-queue/#{@resource['Id']}"]
      }
      @event_subscriptions.push(event_subscription)
    end
  end
end