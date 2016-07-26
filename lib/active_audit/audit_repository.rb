module ActiveAudit
  class AuditRepository
    class << self
      def storage_adapter=(repo_name)
        @@storage_adapter = load_adapter(repo_name)
      end

      def storage_adapter
        @@storage_adapter ||= ActiveAudit::StorageAdapters::TestAdapter
      end

      def find_by_record record, options={}
        storage_adapter.find_by_record(record, options)
      end

      def create attributes
        save Audit.deserialize(attributes)
      end

      def save audit
        audit.save do
          storage_adapter.save audit
        end
      end

      private
        def load_adapter name
          config = \
            begin
              Rails.application.config_for(:active_audit)
            rescue RuntimeError
              {}
            end
          return "ActiveAudit::StorageAdapters::#{name.to_s.camelize}Adapter".constantize.new config
        end
    end
  end
end
