require "rails/observers/activerecord/active_record"
require "rails/observers/action_controller/caching"

module ActiveAudit
  class Sweeper < ActionController::Caching::Sweeper
    observe ActiveAudit::Audit

    def around controller
      begin
        self.controller = controller
        self.user = current_user
        yield
      ensure
        self.controller = nil
        self.user = nil
      end
    end

    def after_initialize audit
      audit.attributed_to = ActiveAudit.extract_user_profile.call(self.user) if self.user
      audit.comment = controller.params[:comment] if controller.respond_to?(:params, true)
      audit.comment ||= ActiveAudit.session[:comment]
    end

    def current_user
      controller.send(ActiveAudit.current_user_method) if controller.respond_to?(ActiveAudit.current_user_method, true)
    end

    def controller
      ActiveAudit.session[:current_controller]
    end

    def controller=(value)
      ActiveAudit.session[:current_controller] = value
    end

    def user
      ActiveAudit.session[:current_user]
    end

    def user=(value)
      ActiveAudit.session[:current_user] = value
    end

  end

  ActiveSupport.on_load(:action_controller) do
    if defined?(ActionController::Base)
      ActionController::Base.around_action ActiveAudit::Sweeper.instance
    end
    if defined?(ActionController::API)
      ActionController::API.around_action ActiveAudit::Sweeper.instance
    end
  end
end
