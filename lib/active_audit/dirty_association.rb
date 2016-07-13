require 'active_support/hash_with_indifferent_access'

module ActiveAudit
  module DirtyAssociation
    extend ActiveSupport::Concern

    class_methods do
      def stain *association_names
        association_names.each do |association_name|
          if reflection = _reflect_on_association(association_name)
            if reflection.collection? && through_refl = reflection.try(:through_reflection)
              through_id = reflection.foreign_key
              through_name = through_refl.name
              define_association_method_suffix association_name
              ActiveRecord::Associations::Builder::CollectionAssociation.define_callback(self, :after_add, through_name, before_add: lambda do |model, relation|
                puts "addubng"
                puts relation.attributes
                DirtyAssociation.record_add association_name, model, relation, through_name, through_id
              end)
              ActiveRecord::Associations::Builder::CollectionAssociation.define_callback(self, :before_remove, through_name, before_remove: lambda do |model, relation|
                DirtyAssociation.record_remove association_name, model, relation, through_name, through_id
              end)
            else
              raise ArgumentError, "'#{association_name}' is not a many-to-many association."
            end
          else
            raise ArgumentError, "No association found for name `#{association_name}'. Has it been defined yet?"
          end
        end
      end


      private
        def define_association_method_suffix association_name
          %w(_changed? _change _was _previously_changed? _previous_change).each do |suffix|
            self.send :define_method, "#{association_name}#{suffix}" do
              send "association#{suffix}", association_name
            end
          end
        end
    end

    attr_reader :association_previous_changes

    def association_changes
      @association_changes ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    def association_changed? association_name
      !!association_changes[association_name]
    end

    def association_change association_name
      association_changes[association_name]
    end

    def association_was association_name
      association_changes[association_name].try '[]', 0
    end

    def association_previously_changed? association_name
      !!association_previous_changes[association_name]
    end

    def association_previous_change association_name
      association_previous_changes[association_name]
    end

    def changes_applied
      super
      @association_previous_changes = association_changes
      @association_changes = ActiveSupport::HashWithIndifferentAccess.new
    end

    module_function
      def init_association_change association_name, model, through, attribute
        old_attributes = model.send(through).map {|r| r.send attribute }
        model.association_changes[association_name] = [old_attributes, old_attributes.dup]
      end

      def record_add association_name, model, relation, through, attribute
        unless model.association_changes[association_name]
          init_association_change association_name, model, through, attribute
        end
        model.association_changes[association_name][1].push relation.send(attribute)
      end

      def record_remove association_name, model, relation, through, attribute
        unless model.association_changes[association_name]
          init_association_change association_name, model, through, attribute
        end
        model.association_changes[association_name][1].delete relation.send(attribute)
      end
  end
end
