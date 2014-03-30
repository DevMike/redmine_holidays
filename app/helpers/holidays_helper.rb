module HolidaysHelper
  def users_collection
    Project.find_by_name('Brightgrove').users.where(:status => 1).map{|u|
      [u.name.gsub(/^\s/,''), u.id]
    }.sort.unshift(['<< me >>', ''])
  end

  def months_collection
    months = []
    current_month_name = Date::MONTHNAMES[Date.today.month]
    (1..12).each {|m|
      name = Date::MONTHNAMES[m]
      months << [name, m, {:class => (name==current_month_name ? 'highlighted' : '')}]
    }
    months
  end

  def years_collection
    current_year = Date.today.year
    [[current_year, current_year], [current_year-1, current_year-1]]
  end

  def day_class(events, day, extra)
    return unless extra
    events.each { |event| return event_class(event) if (event.start_date..event.due_date).include?(day) }
    nil
  end

  def event_class(event)
    event.category.name.downcase.gsub(/\s/, '_') rescue 'vacations'
  end

  def extra_stats(key, year, year_type, kind=:all)
    return if year_type == :previous_year

    case key
      when :"Days Earned"
        if kind == :alt
          "#{@current_year_stats[:days_earned_for_current_year]} days earned in #{year}; #{@current_year_stats[:days_came_from_previous_year]} days earned in #{year-1}"
         else
          " (#{@current_year_stats[:days_earned_for_current_year]} / #{@current_year_stats[:days_came_from_previous_year]})"
        end
      when :"Days Taken"
        if kind == :alt
          "#{@current_year_stats[:days_taken_for_current_year]} days taken in #{year}; #{@current_year_stats[:days_taken_for_previous_year]} days taken in #{year-1}"
        else
          " (#{@current_year_stats[:days_taken_for_current_year]} / #{@current_year_stats[:days_taken_for_previous_year]})"
        end
    end
  end

  def manager_view?(user, project)
    Member.find_by_user_id_and_project_id(user.id, project.id).roles.map(&:name).include?("Manager") rescue false
  end

  def common_event?(event)
    [User::CATEGORY_HOLIDAYS, User::CATEGORY_PARTY].include?(event.category.try(:name))
  end
end
