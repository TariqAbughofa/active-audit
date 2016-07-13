require 'mongo'

module ActiveAudit
  module StorageAdapters
    class MongoAdapter

      def initialize options={}
        client = ::Mongo::Client.new options['hosts'], options['options'].symbolize_keys
        @collection = client[:audits]
      end

      def find_by_record record, options={}
        result = @collection.find(type: record.class.auditing_options[:type], item_id: record.id)
        result.map { |audit| ActiveAudit::Audit.new audit.symbolize_keys }
      end

      def save audit
        @collection.insert_one(audit.attributes)
      end
    end
  end
end
