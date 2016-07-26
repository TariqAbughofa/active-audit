require 'active_support'
require 'active_audit/audit_repository'

module ActiveAudit
  extend ActiveSupport::Autoload

  eager_autoload { autoload :Base }
  autoload :StorageAdapters

  class << self

    attr_accessor :storage_adapter, :current_user_method, :ignored_attributes, :job_queue, :delayed_auditing, :default_user, :extract_user_profile

    def configure
      @current_user_method = :current_user
      @ignored_attributes = %w(created_at updated_at)
      @job_queue = :audits
      @delayed_auditing = false
      @extract_user_profile = lambda { |user| { id: user.id } }
      self.eager_load!
      yield(self) if block_given?
      AuditPusher.queue_as job_queue
      AuditRepository.storage_adapter = storage_adapter if storage_adapter
    end

    def session
      Thread.current[:auditing_store] ||= {}
    end

    def add_hint comment
      self.session[:comment] = comment
    end
  end

end
