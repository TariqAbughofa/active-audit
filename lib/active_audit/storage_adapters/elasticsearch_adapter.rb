require 'elasticsearch/persistence'

module ActiveAudit
  module StorageAdapters
    class ElasticsearchAdapter
      include ::Elasticsearch::Persistence::Repository

      def initialize options={}
        index  options['index'] || :auditing
        client ::Elasticsearch::Client.new url: options['url'] || 'localhost:9200'
        klass ActiveAudit::Audit
      end

      type :_default_

      settings do
        mappings _all: { enabled: false }, date_detection: false, dynamic_templates: [ {
            strings: {
              mapping: {
                index: "not_analyzed",
                type: "string"
              },
              match: "*",
              match_mapping_type: "string"
            }
          } ] do
          indexes :item_id, type: "long"
          indexes :event, type: "string", index: "not_analyzed"
          indexes :changes, type: "object", dynamic: true
          indexes :attributed_to, type: "object", properties: {
            id: { type: "long" },
            name: {type: "string", index: "not_analyzed"}
          }
          indexes :comment, type: "string", index: "not_analyzed"
          indexes :recorded_at, type: "date"
        end
      end

      def find_by_record record, options={}
        self.type "#{record.class.auditing_options[:type]}_events"
        query = {
          query: { filtered: { filter: { bool: { must: [{ term: { item_id: record.id }}]}}}},
          sort: { recorded_at: { order: "desc" }}
        }
        if options[:from] && options[:to]
          query[:query][:filtered][:filter][:bool][:must].push range: { recorded_at: { gte: options[:from], lt: options[:to] }}
        elsif options[:from]
          query[:query][:filtered][:filter][:bool][:must].push range: { recorded_at: { gte: options[:from] }}
        elsif options[:to]
          query[:query][:filtered][:filter][:bool][:must].push range: { recorded_at: { lt: options[:to] }}
        end
        if options[:comment]
          query[:query][:filtered][:filter][:bool][:must].push wildcard: { comment: "*#{options[:comment]}*" }
        end
        search(query).to_a
      end

      define_method :gateway_save, self.new.gateway.method(:save).to_proc

      def save audit
        self.send :gateway_save, audit, type: "#{audit.type}_events"
      end

    end
  end
end
