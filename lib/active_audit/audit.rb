require 'rails/observers/active_model/active_model'
require 'active_model'
require 'virtus'

module ActiveAudit
  class Audit
    include Virtus.model

    extend  ActiveModel::Callbacks
    define_model_callbacks :create, :save
    define_model_callbacks :initialize, :only => :after

    include ActiveModel::Observing

    attribute :item_id, Integer
    attribute :event, String
    attribute :type, String
    attribute :changes, Hash
    attribute :attributed_to, Hash, default: lambda {|o,a| ActiveAudit.default_user }
    attribute :comment, String
    attribute :recorded_at, Time, default: lambda { |o,a| Time.now.utc }

    def initialize *args
      attributes = args.extract_options!
      if attributes.empty?
        if args.count == 2
          initialize_from_record(*args)
          run_callbacks :initialize
        else
          raise ArgumentError, "You need to supply at least one attribute"
        end
      else
        super attributes
      end
    end

    private def initialize_from_record event, record
      if event == 'update'
        if record.respond_to?(:aasm) && record.aasm.current_event
          event = record.aasm.current_event.to_s.sub(/!$/, '')
        end
        self.changes = record.previous_changes.select { |key, value| record.class.auditing_options[:only].include? key }
        self.changes.merge!(record.association_previous_changes.select { |key, value| record.class.auditing_options[:associations].include? key })
        self.changes = self.changes.map do |key, values|
          if values.any? { |v| v.is_a?(Time) }
            [key, values.map { |x| x && x.utc.iso8601 }]
          else
            [key, values]
          end
        end.to_h
      end
      self.event = event
      self.type = record.class.auditing_options[:type]
      self.item_id = record.id
      set_default_attributes
    end

    def changed?
      ['create', 'destroy'].include?(self.event) || changes.present?
    end

    def save options={}
      self.run_callbacks :save do
        self.run_callbacks :create do
          yield if changed?
        end
      end
    end

    def self.create(attributes, options={})
      object = self.new(attributes)
      object.save(options)
      object
    end

    def self.serialize audit
      audit.attributes.select {|k,v| v.present?}.merge(recorded_at: audit.recorded_at.to_i)
    end

    def self.deserialize attributes
      self.new attributes.update(recorded_at: Time.at(attributes[:recorded_at]))
    end
  end
end
