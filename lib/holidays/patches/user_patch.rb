require_dependency 'user'

module Calculation
  module DaysEarned
    def days_earned(on_date, for_current, extra_days)
      year_end_date = for_current ? on_date.at_end_of_year : 1.year.ago.at_end_of_year.to_date
      year_start_date = for_current ? on_date.at_beginning_of_year : 1.year.ago.at_beginning_of_year

      return 0 if created_on.to_date.year > year_end_date.year

      worked_out_days = (for_current ? on_date : year_end_date) - [year_start_date.to_date, created_on.to_date].max
      value = (worked_out_days.to_i.to_f * User::EARNED_DAYS_PER_YEAR / 365).round(1).ceil + extra_days
      value < 0 ? 0 : value
    end
  end

  module DaysTaken
    def days_taken_for(to, for_current, category=User::CATEGORY_VACATIONS)
      date_for_year = for_current ? Date.today : 1.year.ago
      year_beginning = date_for_year.at_beginning_of_year
      to = if to
             to
           elsif for_current
           elsif for_current
             Date.today
           else
             date_for_year.at_end_of_year
           end

      value = calculate_days_taken(year_beginning, to, category)
      for_current && category==User::CATEGORY_VACATIONS ? (value - days_taken_from_previous.to_i) : value
    end

    def consider_taken_for_previous(for_current, to, on_date,  year_days_earned)
      days_taken = days_taken_for(to, for_current)
      days_left_value = if for_current
                          @previous_year_stats = year_stats(@project, @holiday_dates, false, on_date)
                          @previous_year_stats[:"Days Left"]
                        else
                          days_left(year_days_earned, days_taken)
                        end
      if days_taken_from_previous.blank?
        taken_before_burning = calculate_days_taken(Date.today.at_beginning_of_year, [User::DATE_WHEN_EXTRA_BURNING, on_date].min)
        self.days_taken_from_previous = taken_before_burning < days_left_value ? taken_before_burning : days_left_value
      end

      if for_current
        days_taken - days_taken_from_previous
      else
        days_taken + days_taken_from_previous
      end
    end

    def calculate_days_taken(from, to, category=User::CATEGORY_VACATIONS)
      @project.issues.where('start_date BETWEEN ? AND ? OR due_date BETWEEN ? AND ?', from, to, from, to).
          joins('LEFT JOIN issue_categories ic ON issues.category_id = ic.id').
          where('ic.id IS NULL OR ic.name = ?', category).
          where(:assigned_to_id => id).inject(0){|sum, i|
            sum += i.days_taken(@holiday_dates, from, to)
          }
    end
  end
end

module Holidays
  module Patches
    module UserPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          base.send(:include, InstanceMethods)

          unloadable # Send unloadable so it will not be unloaded in development

          serialize :extra_days
          after_initialize :set_extra_days, :if => ->(u){ u.extra_days.blank? }

          before_save :remove_spaces_from_names
        end
      end
    end

    module InstanceMethods
      include Calculation::DaysEarned
      include Calculation::DaysTaken

      attr_accessor :days_taken_from_previous

      EARNED_DAYS_PER_YEAR = 20
      CATEGORY_HOLIDAYS = 'Holidays'
      CATEGORY_VACATIONS = 'Vacations'
      CATEGORY_SICK_DAYS = 'Sick Days'
      CATEGORY_TRAININGS = 'Trainings'
      CATEGORY_PARTY = 'Party'
      DATE_WHEN_EXTRA_BURNING = Date.today.at_beginning_of_year+2.months

      def set_extra_days
        self.extra_days = {:current_year => 0, :previous_year => 0}
      end

      def remove_spaces_from_names
        self.firstname = firstname.gsub(/\s/, '') if firstname.present?
        self.lastname = lastname.gsub(/\s/, '') if lastname.present?
      end

      def year_stats(project, holiday_dates, for_current=true, to=nil)
        @project ||= project
        @holiday_dates ||= holiday_dates
        on_date = to ? to : Date.today

        year_extra_days = self.extra_days[for_current ? :current_year : :previous_year].to_i
        year_days_earned = days_earned(on_date, for_current, year_extra_days)
        year_days_taken = if days_taken_from_previous.nil?
                            consider_taken_for_previous(for_current, (for_current ? to : nil), on_date, year_days_earned)
                          else
                            days_taken_for(to, for_current)
                          end
        days_left_value = !for_current && on_date > DATE_WHEN_EXTRA_BURNING ? 0 : days_left(year_days_earned, year_days_taken, (for_current ? @previous_year_stats : nil), for_current, to)

        {
          :"Days Earned" => year_days_earned,
          :"Days Taken" => year_days_taken,
          :"Days Left" => days_left_value,
          :"Extra Days" => year_extra_days,
          :"Sick Days" => days_taken_for(to, for_current, User::CATEGORY_SICK_DAYS),
          :"Trainings" => days_taken_for(to, for_current, User::CATEGORY_TRAININGS)
        }
      end

      def days_left(days_earned, days_taken, previous_year_stats=nil, for_current=nil, to=nil)
        days_number = days_earned - days_taken
        if previous_year_stats.present?
          days_number += if for_current && to && to < DATE_WHEN_EXTRA_BURNING
                           previous_year_stats[:"Days Left"]
                         else
                           0
                         end
        end
        days_number < 0 ? 0 : days_number
      end
    end
  end
end

unless User.included_modules.include?(Holidays::Patches::UserPatch)
  User.send(:include, Holidays::Patches::UserPatch)
end