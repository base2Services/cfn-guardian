module CfnGuardian
    class ValidationError < StandardError; end
    class TemplateValidationError < StandardError; end
    class EmptyChangeSetError < StandardError; end
    class ChangeSetError < StandardError; end
end