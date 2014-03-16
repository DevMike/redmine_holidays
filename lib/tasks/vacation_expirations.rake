namespace :holidays do
  desc 'sends vacation expiration notification'
  task :send_vacation_expiration_notification => :environment do
    $project = Project.find_by_name('Holidays')
    $holidays = project.issues.joins(:category).where(:category_id => IssueCategory.find_by_name(User::CATEGORY_HOLIDAYS).id)
    User.all.select do |user|
      user.instance_eval do
        def days_to_be_expired
          previous_year_stats = year_stats($project, $holidays, false)
          current_year_stats = year_stats($project, $holidays, true, previous_year_stats)
          current_year_stats[:days_came_from_previous_year] - current_year_stats[:days_taken_for_previous_year]
        end
      end
      user.days_to_be_expired > 0
    end.group_by(&:manager).each do |manager_users|
      if manager_users[0].present?
        user = User.find_by_lastname(manager_users[0].split(/\s/).last)
        Mailer.vacations_expiration(user, manager_users[1]).deliver!
      end
    end
  end
end