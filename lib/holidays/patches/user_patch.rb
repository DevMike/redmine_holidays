require_dependency 'user'

module DaysEarned
  def days_earned
    if @for_current && @on_date < User::DATE_WHEN_EXTRA_BURNING
      @days_earned_for_current_year + @previous_year_stats[:"Days Left"]
    else
      @days_earned_for_current_year + @days_came_from_previous_year
    end
  end

  def days_earned_for_current_year
    year_end_date = @for_current ? @on_date.at_end_of_year : 1.year.ago.at_end_of_year.to_date
    year_start_date = @for_current ? @on_date.at_beginning_of_year : 1.year.ago.at_beginning_of_year

    return 0 if created_on.blank? || created_on.year > year_end_date.year

    worked_out_days = if @for_current
                        @on_date - year_start_date
                      else
                        year_end_date - [year_start_date.to_date, appearance_date.to_date].max
                      end
    @days_earned_for_current_year = (worked_out_days.to_i.to_f * User::EARNED_DAYS_PER_YEAR / 365).round(1).ceil
  end

  def days_came_from_previous_year
    return 0 unless @for_current
    return @days_taken_for_previous_year if @on_date >= User::DATE_WHEN_EXTRA_BURNING

    days_earned_from_previous_year = @previous_year_stats[:"Days Left"]
    [@days_taken_for_previous_year, days_earned_from_previous_year].max
  end
end

module DaysTaken
  def days_taken_for_previous_year
    return 0 unless @for_current
    calculate_days_taken(Date.today.at_beginning_of_year, User::DATE_WHEN_EXTRA_BURNING)
  end

  def days_taken_for_current_year(category=User::CATEGORY_VACATIONS)
    date_for_year = @for_current ? Date.today : 1.year.ago
    year_beginning = date_for_year.at_beginning_of_year
    to = if @to
           @to
         elsif @for_current
           Date.today
         else
           date_for_year.at_end_of_year
         end

    calculate_days_taken(year_beginning, to, category)
  end

  def calculate_days_taken(from, to, category=User::CATEGORY_VACATIONS)
    @project.issues.where('start_date BETWEEN ? AND ? OR due_date BETWEEN ? AND ?', from, to, from, to).
        joins('LEFT JOIN issue_categories ic ON issues.category_id = ic.id').
        where('ic.id IS NULL OR ic.name = ?', category).
        where(:assigned_to_id => id).all.inject(0){|sum, i|
          sum += i.days_taken(@holiday_dates, from, to)
        }
  end
end

module Holidays
  module Patches
    module UserPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          base.extend(ClassMethods)
          base.send(:include, InstanceMethods)

          unloadable # Send unloadable so it will not be unloaded in development

          serialize :extra_days
          after_initialize :set_extra_days, :if => ->(u){ u.extra_days.blank? }
        end
      end
    end

    module ClassMethods
      User::EARNED_DAYS_PER_YEAR = Setting['earned_days_per_year'].to_i rescue false || 20
      User::CATEGORY_HOLIDAYS = 'Holidays'
      User::CATEGORY_VACATIONS = 'Vacations'
      User::CATEGORY_SICK_DAYS = 'Sick Days'
      User::CATEGORY_TRAININGS = 'Trainings'
      User::CATEGORY_PARTY = 'Party'
      User::DATE_WHEN_EXTRA_BURNING = Date.parse("#{Settings['date_when_extra_days_burning']}-#{Date.today.year}") rescue Date.today.at_beginning_of_year+2.months
    end

    module InstanceMethods
      include DaysEarned
      include DaysTaken

      def set_extra_days
        self.extra_days = {:current_year => 0, :previous_year => 0}
      end

      def year_stats(project, holiday_dates, for_current=true, previous_year_stats=nil, to=nil, by_day=false)
        @project = project
        @holiday_dates = holiday_dates
        @previous_year_stats = by_day && for_current ? year_stats(project, holiday_dates, false, nil, nil) : previous_year_stats
        @to = to
        @for_current = for_current
        @on_date = @to ? @to : Date.today

        @extra_days = self.extra_days[@for_current ? :current_year : :previous_year].to_i
        @days_taken_for_previous_year = days_taken_for_previous_year
        @days_taken_for_current_year = days_taken_for_current_year
        @days_came_from_previous_year = days_came_from_previous_year
        @days_earned_for_current_year = days_earned_for_current_year
        @days_earned = days_earned

        {
          :"Days Earned" => @days_earned,
          :days_came_from_previous_year => @days_came_from_previous_year,
          :days_earned_for_current_year => @days_earned_for_current_year,
          :"Days Taken" => @days_taken_for_current_year,
          :"Days Left" => days_left,
          :"Extra Days" => @extra_days,
          :"Sick Days" => days_taken_for_current_year(User::CATEGORY_SICK_DAYS),
          :"Trainings" => days_taken_for_current_year(User::CATEGORY_TRAININGS),
          :days_taken_for_previous_year => @days_taken_for_previous_year,
          :days_taken_for_current_year => @days_taken_for_current_year
        }
      end

      def days_left
        days_number = @days_earned - @days_taken_for_current_year + @extra_days
        if @for_current
          days_from_previous_year = @previous_year_stats[:"Days Taken"] - @previous_year_stats[:"Days Earned"]
          days_number -= days_from_previous_year if days_from_previous_year > 0
        end
        days_number < 0 ? 0 : days_number
      end
    end
  end
end

unless User.included_modules.include?(Holidays::Patches::UserPatch)
  User.send(:include, Holidays::Patches::UserPatch)
end
