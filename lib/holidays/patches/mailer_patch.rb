require_dependency 'mailer'

module Holidays
  module Patches
    module MailerPatch
      def self.included(receiver)
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          unloadable
        end
      end

      module InstanceMethods
        def vacations_expiration(manager, users)
          @users = users
          mail :to => manager.mail,
               :subject => "Vacations expiration"
        end
      end
    end
  end
end

unless Mailer.included_modules.include?(Holidays::Patches::MailerPatch)
  Mailer.send(:include, Holidays::Patches::MailerPatch)
end   

