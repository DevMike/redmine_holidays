class HolidaysController < ApplicationController
  unloadable
  helper :calendars
  include CalendarsHelper

  before_filter :set_holidays, :only => [:index, :day_stats]

  def index
    @user = User.find(params[:user]) rescue User.current

    @year = params[:year] ? params[:year].to_i : Date.today.year
    @month = params[:month] ? params[:month].to_i : Date.today.month

    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
    extract_events

    @closest_event = @rejoicings.where('due_date > ? OR start_date > ?', Date.today, Date.today).
        order(:start_date).first rescue nil

    year_beginning = Date.today.at_beginning_of_year
    @year_events = @rejoicings.where('start_date > ? OR due_date > ?', year_beginning, year_beginning)

    @previous_year_stats = @user.year_stats(@project, @holiday_dates, false)
    @current_year_stats = @user.year_stats(@project, @holiday_dates, true)
  end

  def update_extra_days
    success = unless %w[current_year previous_year].include?(params[:year]) && params[:extra_days] =~ /^-?\d+$/
                false
              else
                user = User.find(params[:user])
                user.extra_days[params[:year].to_sym] = params[:extra_days].to_i
                user.save
              end
    redirect_to holidays_path(:user => params[:user]), :notice => (success ? 'Extra days updated' : 'Please correct extra_days value')
  end

  def day_stats
    stats = User.find(params[:user_id]).year_stats(@project, @holiday_dates, params[:for_current]=='true', params[:date].to_date)
    render :json => { :days_earned => stats[:'Days Earned'], :days_left => stats[:'Days Left'] }
  end

  def extract_events
    @events = Issue.joins(:category).where(:project_id => @project.id).
                    where("((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))",
                          @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt).
                    order("CASE issue_categories.name WHEN '#{User::CATEGORY_PARTY}' THEN 1
                                                      WHEN '#{User::CATEGORY_HOLIDAYS}' THEN 2
                                                      WHEN '#{User::CATEGORY_VACATIONS}' THEN 3
                                                      WHEN '#{User::CATEGORY_TRAININGS}' THEN 4
                                                      ELSE 5 END")
    if params[:user].present? && !(@user.admin? ||
        (Member.find_by_user_id_and_project_id(@user.id, @project.id).roles.map(&:name).include?("Manager") rescue false))
      @events = @events.where('issues.assigned_to_id = ? OR issues.category_id = ?', @user.id, @category_holidays_id)
    end
  end

private
  def set_holidays
    @project = Project.find_by_name('Holidays')
    @category_holidays_id = IssueCategory.find_by_name(User::CATEGORY_HOLIDAYS).id

    @rejoicings = @project.issues.where(:category_id => IssueCategory.where(name: [User::CATEGORY_PARTY, User::CATEGORY_HOLIDAYS]))

    @holidays_events = @project.issues.joins(:category).where(:category_id => @category_holidays_id)
    @holidays_dates = @holidays_events.map{|i|
      {:start_date => i.start_date.to_date, :due_date => i.due_date.to_date}
    } rescue []
  end
end
