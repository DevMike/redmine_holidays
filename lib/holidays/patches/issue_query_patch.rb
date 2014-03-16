require_dependency 'issue_query'

module Holidays
  module Patches

    module IssueQueryPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          base.send(:include, InstanceMethods)
          base.send(:extend, ClassMethods)

          base.add_available_column(QueryColumn.new(:days_taken, :sortable => "DATEDIFF(#{Issue.table_name}.due_date, #{Issue.table_name}.start_date)"))

          unloadable # Send unloadable so it will not be unloaded in development

          alias_method_chain :initialize_available_filters, :days_taken
        end
      end
    end

    module ClassMethods
      # Setter for +available_columns+ that isn't provided by the core.
      def available_columns=(v)
        self.available_columns = (v)
      end

      # Method to add a column to the +available_columns+ that isn't provided by the core.
      def add_available_column(column)
        self.available_columns << (column)
      end
    end

    module InstanceMethods
      def initialize_available_filters_with_days_taken
        initialize_available_filters_without_days_taken
        add_available_filter "days_taken", :type => :integer if project && project.name == 'Holidays'
      end
    end
  end
end

unless IssueQuery.included_modules.include?(Holidays::Patches::IssueQueryPatch)
  IssueQuery.send(:include, Holidays::Patches::IssueQueryPatch)
end