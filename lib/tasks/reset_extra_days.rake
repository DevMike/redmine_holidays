namespace :holidays do
  desc 'reset extra_days value'
  task :reset_extra_days => :environment do
    User.all.each do |u|
      u.extra_days = {
        :current_year => 0,
        :previous_year => u.extra_days[:current_year]
      }
      u.save!(:validate => false)
    end
  end
end