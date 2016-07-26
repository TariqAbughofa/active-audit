require 'active_audit/errors'
require 'active_audit/audit'
require 'active_audit/audit_pusher'
require 'active_audit/dirty_association'
require 'active_audit/sweeper'

module ActiveAudit
  module Base
    extend ActiveSupport::Concern
    include DirtyAssociation

    class_methods do

      def auditing_options
        @auditing_options ||= {
          type: self.to_s.underscore,
          only: self.attribute_names - ActiveAudit.ignored_attributes
        }
      end

      def audit *args
        options = args.extract_options!.dup
        options.assert_valid_keys(:type, :except, :associations, :unless)
        options[:type] = options[:type].to_s if options[:type]
        except = options[:except] ? options[:except].map(&:to_s) : []
        only = if args.present? then args.map(&:to_s) else auditing_options[:only] end
        options[:only] = only - except
        if options[:associations]
          options[:associations] = options[:associations].map(&:to_s)
          stain *options[:associations]
        end
        auditing_options.update options
      end

    end

    included do
      if self < ActiveRecord::Base
        after_commit on: [:create] { write_audit('create') }
        after_commit on: [:update] { write_audit('update') }
        after_commit on: [:destroy] { write_audit('destroy') }
      elsif defined?(Mongoid::Document) && self < Mongoid::Document
        after_create { write_audit('create') }
        after_update { write_audit('update') }
        after_destroy { write_audit('destroy') }
      else
        raise Errors::UnsupportedModel, "can audit ActiveRecord and Mongoid models only"
      end
    end

    def audits options={}
      AuditRepository.find_by_record self, options
    end

    private
      def audited?
        if condition = self.class.auditing_options[:unless]
          case condition
            when Symbol, String
              self.public_send condition
            when Proc
              condition.call self
          end
        end
        return true
      end

      def write_audit event
        if audited?
          audit = Audit.new event, self
          if audit.changed?
            if ActiveAudit.delayed_auditing
              AuditPusher.perform_later Audit.serialize(audit)
            else
              AuditRepository.save(audit)
            end
          end
        end
      end

  end
end
