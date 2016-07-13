module ActiveAudit
  module StorageAdapters
    extend ActiveSupport::Autoload

    autoload :ActiveRecordAdapter
    autoload :ElasticsearchAdapter
    autoload :MongoAdapter
    autoload :TestAdapter
  end
end
