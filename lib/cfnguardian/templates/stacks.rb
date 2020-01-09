require 'cfndsl'

CloudFormation do
  
  Description("CFN Guardian")

  Parameter(:Critical) {
    Type 'String'
    Description 'SNS Topic Arn for critical notifications'
  }
  
  Parameter(:Warning) {
    Type 'String'
    Description 'SNS Topic Arn for warning notifications'
  }
  
  Parameter(:Task) {
    Type 'String'
    Description 'SNS Topic Arn for task notifications'
  }
  
  Parameter(:Informational) {
    Type 'String'
    Description 'SNS Topic Arn for informational notifications'
  }
  
  stacks = external_parameters.fetch(:stacks, [])
  
  stacks.each do |stack|
    CloudFormation_Stack(stack['Name']) {
      Parameters({
        Critical: Ref(:Critical),
        Warning: Ref(:Warning),
        Task: Ref(:Task),
        Informational: Ref(:Informational)
      })
      TemplateURL stack['TemplateURL']
      TimeoutInMinutes 15
    }
  end
  
end
