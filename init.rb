require 'holidays'

Redmine::Plugin.register :redmine_holidays do
  name 'Holidays'
  author 'Mike Zarechenskiy'
  description 'This is a holidays plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/DevMike/redmine_holidays'
  author_url 'https://github.com/DevMike'

  menu :top_menu, :holidays, { :controller => 'holidays', :action => 'index' }, :caption => "Holidays"

  settings :default => {'empty' => true}
end
