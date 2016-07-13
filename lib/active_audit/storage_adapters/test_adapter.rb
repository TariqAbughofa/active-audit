module ActiveAudit
  module StorageAdapters
    class TestAdapter

      class << self
        def find_by_record record, options={}
          raise NotImplementedError.new "can not retrieve audits with `TestAdapter`."
        end

        def save audit
          Rails.logger.info "audit -> #{audit.attributes}"
        end
      end

    end
  end
end
