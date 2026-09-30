module CfnGuardian::Resource
  # Monitors ECS tasks that run outside of an ECS service, such as tasks launched
  # by an EventBridge rule or EventBridge Scheduler. These tasks have no service
  # metrics, so failures are detected from the ECS Task State Change events.
  # The cluster and task definition family scope is applied by
  # ECSScheduledTaskEventSubscription, so custom subscriptions get it too.
  class ECSScheduledTask < Base

    def default_event_subscriptions()
      event_subscription = CfnGuardian::Models::ECSScheduledTaskEventSubscription.new(@resource)
      event_subscription.name = 'TaskFailed'
      event_subscription.detail = {
        'lastStatus' => ['STOPPED'],
        'containers' => { 'exitCode' => [{ 'anything-but' => 0 }] }
      }
      @event_subscriptions.push(event_subscription)

      event_subscription = CfnGuardian::Models::ECSScheduledTaskEventSubscription.new(@resource)
      event_subscription.name = 'TaskFailedToStart'
      event_subscription.detail = {
        'lastStatus' => ['STOPPED'],
        'stopCode' => ['TaskFailedToStart']
      }
      @event_subscriptions.push(event_subscription)
    end

  end
end
