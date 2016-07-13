ActiveAudit.configure do |config|
  config.storage_adapter = :<%= adapter.to_sym %>
  #config.current_user_method = :current_user
  #config.ignored_attributes = %w(created_at updated_at)
  #config.job_queue = :audits
  #config.delayed_auditing = false
  #config.default_user = { id: 1 }
  #config.extract_user_profile = lambda { |user| { id: user.id } }
end
