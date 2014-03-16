require_dependency 'calendars_controller'

module Holidays
  module Patches
    module CalendarsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          before_filter :redirect_to_index, :only => :show
        end
      end

      module InstanceMethods
        def redirect_to_index
          redirect_to holidays_path and return false if params[:project_id] == 'holidays'
        end
      end
    end
  end
end

unless CalendarsController.included_modules.include?(Holidays::Patches::CalendarsControllerPatch)
  CalendarsController.send(:include, Holidays::Patches::CalendarsControllerPatch)
end