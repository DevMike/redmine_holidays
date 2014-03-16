require_dependency 'query'

module Holidays
  module Patches

    module QueryColumnPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          base.send(:include, InstanceMethods)

          unloadable # Send unloadable so it will not be unloaded in development

          alias_method_chain :value, :days_taken
        end
      end
    end

    module InstanceMethods
      def value_with_days_taken(object)
        if object.project.name == 'Holidays' && name == :days_taken
          object.days_taken
        else
          value_without_days_taken(object)
        end
      end
    end
  end
end

unless QueryColumn.included_modules.include?(Holidays::Patches::QueryColumnPatch)
  QueryColumn.send(:include, Holidays::Patches::QueryColumnPatch)
end