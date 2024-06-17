require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
time_target = Hash.new(0)

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

def get_best_time(time_target)
  string_to_time = Time.strptime("#{time_target.keys.map!(&:to_i).max}:00", "%H:%M")
  formatted_time = string_to_time.strftime("%I:%M %p")
  formatted_time 
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
  registration_date = append_time(row[:regdate], time_target)
  
  # legislators = legislators_by_zipcode(zipcode)
  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id,form_letter)
end

puts "Best time to advertize within the day is: #{get_best_time(time_target)}"
