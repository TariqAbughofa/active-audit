require 'rails/generators'
require 'rails/generators/active_record'

module ActiveAudit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      desc "Create initializer and config files for active audit base on the adapter you define. In case of 'active_record' adapter a migration will be generated as well."

      argument :adapter, required: true, type: :string, default: "test", desc: "The name of the storage adapter you want to use.",
           :banner => "adapter_name"

      source_root File.expand_path("../templates", __FILE__)

      def copy_initializer_file
        template "initializer.rb", "config/initializers/active_audit.rb"
        unless adapter == 'active_record' || adapter == 'test'
          copy_file "#{adapter}_config.yml", "config/active_audit.yml"
        end
      end

      def generate_migration
        if adapter == 'active_record'
          migration_template 'migration.rb', 'db/migrate/create_audits.rb'
        end
      end

    end
  end
end
