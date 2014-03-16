Rails.configuration.to_prepare do
  require_dependency 'holidays/patches/calendars_controller_patch'
  require_dependency 'holidays/patches/issue_patch'
  require_dependency 'holidays/patches/issue_query_patch'
  require_dependency 'holidays/patches/mailer_patch'
  require_dependency 'holidays/patches/query_patch'
  require_dependency 'holidays/patches/user_patch'
end
