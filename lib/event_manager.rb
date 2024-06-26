require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
time_target = Hash.new(0)
day_target = Hash.new(0)

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^0-9]/, '')

  if phone_number.length.eql?(10)
    phone_number
  elsif phone_number.length.eql?(11) && phone_number.start_with?('1')
    phone_number[1..-1]
  else
    "Bad Number"
  end
end

def append_time(registration_date, time_target)
  hour = Time.strptime(registration_date, '%m/%d/%y %H:%M').strftime("%H")
  time_target[hour] = time_target[hour] + 1
end

def append_day(registration_date, day_target)
  day = Date.strptime(registration_date, '%m/%d/%y %H:%M').wday
  day_target[day] = day_target[day] + 1
end

def get_best_time(time_target)
  time = time_target.select { |hour, count| count == time_target.values.max_by(&:itself) }.keys
  time.map! { |hour| Time.strptime(hour, '%H').strftime('%I:%M %p') }
  time.join(", ")
end

def get_best_day(day_target)
  day = day_target.select { |day, count| count == day_target.values.max_by(&:itself) }.keys
  day.map! { |day| "#{day} (#{Date.strptime(day.to_s, '%w').strftime('%A')})" }
  day.join(", ")
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])

  # Get Hour of the regdates
  append_time(row[:regdate], time_target)

  # Get Day of the regdates
  append_day(row[:regdate], day_target)
  
  # legislators = legislators_by_zipcode(zipcode)
  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id,form_letter)
end

puts "Best time to advertize within the day is/are: #{get_best_time(time_target)}"
puts "Best time to advertize within the week is/are: #{get_best_day(day_target)}"
