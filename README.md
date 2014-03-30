## Redmine Holidays

The plugin provides ability to manage following types of events:
* Vacations(marked yellow on calendar)
* Holidays(marked red on calendar)
* Parties(marked orange on calendar)
* Sick days(marked blue on calendar)
* Trainings(marked green on calendar)

## Requirements

* Redmine 2.4+
* Ruby 1.9.3+

## Installation

Move to the 'plugins' directory of your application and then run following::

       git clone git://github.com/DevMike/redmine_holidays.git
       bundle install
       bundle exec rake redmine:plugins NAME=redmine_holidays RAILS_ENV=production

Then restart rails server.

## How it works

### Sidebar
#### Days Earned
Each user has a fixed value of days earned per year - 20. It's defined there https://github.com/DevMike/redmine_holidays/blob/master/lib/holidays/patches/user_patch.rb#L87 at the moment(will be implemented as a changeable setting soon).
Current value that is shown on the view means how many days the user has earned for today. For example, if today is 4th January, then the value is 1.
Rounding: if tenths of number is more then 0.1 then it rounds upward. Examples:
1.09 rounds as 1
1.1 rounds as 2
Note, that parameter created_on is used for calculation instead of year start date if user registration happened later. For example, if user registered at 1st December and now is 3rd December then the value is 1

#### Days Taken
Days sum of all issues assigned to category Vacations for a year.
An important thing concerning it is that if user has unused(Days Left) days from previous year and 'date of burning'(1tst March; at the moment defined there https://github.com/DevMike/redmine_holidays/blob/master/lib/holidays/patches/user_patch.rb#L93 ) has not passed yet, then the days take into account as days taken of previous year

#### Days Left
Formula: 'Days Earned' - 'Days Taken'
If the date of burning described in the previous item passed, then this value will became 0 for previous year in any case

### Month view
Shows all types of events for current month.
Hovering on an event shows start date and due date(end date) of the event
Clicking by day shows short statistics for this day: Days earned and Days left(including ones from previous year)

### Year holidays
Shows parties and holidays for whole year


Feel free to contact me if there are any questions
