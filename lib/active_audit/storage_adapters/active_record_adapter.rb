module ActiveAudit
  module StorageAdapters
    class ActiveRecordAdapter

      def initialize options={}
        @connection = ::ActiveRecord::Base.connection
      end

      def find_by_record record, options={}
        result = @connection.exec_query "SELECT * FROM audits WHERE item_id=$1 AND type=$2 ORDER BY recorded_at DESC;", nil, [[nil, record.id], [nil,record.class.auditing_options[:type]]]
        result.map { |attributes| ActiveAudit::Audit.new attributes }
      end

      def save audit
        @connection.exec_query('INSERT INTO audits("item_id", "event", "type", "changes", "user_id", "user", "comment", "recorded_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8);', nil, [
          [nil, audit.item_id],
          [nil, audit.event],
          [nil, audit.type],
          [nil, audit.changes.to_json],
          [nil, audit.user[:id]],
          [nil, audit.user.to_json],
          [nil, audit.comment],
          [nil, audit.recorded_at]
        ])
      end
    end
  end
end
