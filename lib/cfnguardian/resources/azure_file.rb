module CfnGuardian::Resource
    class AzureFile < Base

      def default_alarms
        alarm = CfnGuardian::Models::AzureFileAlarm.new(@resource)
        alarm.name = 'FileExpired'
        alarm.metric_name = 'FileExpired'
        @alarms.push(alarm)
      end

      def default_events
        @events.push(CfnGuardian::Models::AzureFileEvent.new(@resource))
      end

      def default_checks
        @checks.push(CfnGuardian::Models::AzureFileCheck.new(@resource))
      end

    end
  end