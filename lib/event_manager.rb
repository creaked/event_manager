require 'csv'
require 'sunlight/congress'
require 'erb'
require 'date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_numbers(phone_number)
  phone_number = phone_number.to_s.scan(/\d/).join
  phone_number[0] == '' if phone_number[0] == '1'
  phone_number.rjust(10,'0')[0..9]
end

def strip_date(date)
  date = DateTime.strptime(date.to_s, '%m/%d/%Y %k:%M')
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id,form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"
  filename = "output/thanks_#{id}.html"
  
  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager initialized."

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
hour_target = []
day_target = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_numbers(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  registration_date = strip_date(row[:regdate])
  hour_target.push(registration_date.hour)
  day_target.push(registration_date.wday)
  
  form_letter = erb_template.result(binding)
  
  save_thank_you_letters(id,form_letter)
end

# time targeting
puts "Registered [WeekDay, Frequency]: #{day_target.each_with_object(Hash.new(0)){ |m,h| h[m] += 1 }.sort_by{ |k,v| v }}"
puts "Registered [Hour, Frequency]: #{hour_target.each_with_object(Hash.new(0)){ |m,h| h[m] += 1 }.sort_by{ |k,v| v }}"
