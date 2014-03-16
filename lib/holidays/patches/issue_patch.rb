require_dependency 'issue'

module Holidays
  module Patches

    module IssuePatch
      def self.included(base) # :nodoc:
        base.class_eval do
          base.send(:include, InstanceMethods)

          unloadable # Send unloadable so it will not be unloaded in development

          alias_method_chain :safe_attribute?, :holidays

          validates_presence_of :category_id, :start_date, :due_date, :if => :project_holidays?
          validates_presence_of :assigned_to_id, :if => ->{
            project_holidays? && category.present? && [User::CATEGORY_VACATIONS, User::CATEGORY_SICK_DAYS, User::CATEGORY_TRAININGS].include?(category.name)
          }
        end
      end
    end

    module InstanceMethods
      def project_holidays?
        project.present? && project.name == 'Holidays'
      end

      def days_taken(holiday_dates=nil, from = nil, to=nil)
        unless holiday_dates
          holiday_dates = project.issues.joins(:category).
              where(:category_id => IssueCategory.find_by_name(User::CATEGORY_HOLIDAYS).id).map{|i|
                {:start_date => i.start_date.to_date, :due_date => i.due_date.to_date}
              } rescue []
        end

        sum = 0
        vacation_date = start_date
        begin
          until vacation_date > due_date do
            if (from.blank? || (from.to_date..to.to_date).include?(vacation_date)) && ![0, 6].include?(vacation_date.wday) &&
                !holiday_dates.any?{|date| (date[:start_date]..date[:due_date]).include?(vacation_date)}
              sum += 1
            end
            vacation_date += 1.day
          end
          sum
        rescue
          0
        end
      end

      def safe_attribute_with_holidays?(*args)
        if project.name == 'Holidays' &&
            %w[tracker_id done_ratio estimated_hours parent_issue_id priority_id checklist_item_input description].include?(args[0]) ||
            (%w[assigned_to_id category_id].include?(args[0]) && !User.current.allowed_to?(:add_issues, project))
          false
        else
          safe_attribute_without_holidays?(*args)
        end
      end
    end
  end
end

unless Issue.included_modules.include?(Holidays::Patches::IssuePatch)
  Issue.send(:include, Holidays::Patches::IssuePatch)
end