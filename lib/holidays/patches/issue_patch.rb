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
          validate :dates_on_duplication, :if => :project_holidays?
        end
      end
    end

    module InstanceMethods
      def project_holidays?
        project.present? && project.name == 'Holidays'
      end

      def dates_on_duplication
        if project.issues.joins(:category).
            where(id.present? ? "#{self.class.table_name}.id != #{id}" : '').
            where(:assigned_to_id => assigned_to_id).
            where(:category_id => IssueCategory.find_by_name(User::CATEGORY_VACATIONS).id).
            where('start_date BETWEEN ? AND ? OR due_date BETWEEN ? AND ?', start_date, due_date, start_date, due_date).any?
          errors.add(:start_date, 'Vacation for this user is already exists in mentioned date range')
          errors.add(:due_date, 'Vacation for this user is already exists in mentioned date range')
        end
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
        until vacation_date > [due_date, (to ? to.to_date : due_date)].min do
          if (from.blank? || (from.to_date..to.to_date).include?(vacation_date)) && ![0, 6].include?(vacation_date.wday) &&
              !holiday_dates.any?{|date| (date[:start_date]..date[:due_date]).include?(vacation_date)}
            sum += 1
          end
          vacation_date += 1.day
        end
        sum
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