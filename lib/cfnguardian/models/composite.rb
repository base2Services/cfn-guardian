module CfnGuardian
  module Models
    class Composite
      
      attr_reader :type
      attr_accessor :name,
        :description,
        :rule,
        :alarm_action
        
      def initialize(name,params = {})
        @type = 'Composite'
        @name = name
        @description = params.fetch('Description', '')
        @rule = params.fetch('Rule', 'FALSE')
        @alarm_action = params.fetch('Action', nil)
      end
              
    end
  end
end