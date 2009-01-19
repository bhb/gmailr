require 'highline/import'
require 'send_gmail'

def get_password(username)
  password = ask("password for #{username}:") { |q| q.echo = false }
  password
end

# This field must be your Gmail account
username = "your_gmail_account@gmail.com"

# This can be another email address (in my case, ben@devver.net)
from = "you@another_domain.com"
domain = "gmail.com"

# Add any addresses you would like CCed
cc = ""

subject = "[Your subject here]"

# Fill this hash with email addresses and salutations. 
to = {
  "john@doe.com" => "John",
  "sally@ssmith.com" => "Dr. Smith"
}
salutation = ",\n\n"
file = ask("file containing message: ").chomp
message = File.read(file)
puts "To: #{to.map{|k,v| "#{k} (#{v})"}.join(" ,")}"
puts "From: #{from}"
puts "CC: #{cc}"
puts "Subject: #{subject}"
puts "Message:\n[name]#{salutation}#{message}"
continue = ask("Is this message OK? [yes/no]:")
if(continue=="yes")
  password = get_password(username)
  tries = 3
  begin
    to.each do |email,name|
      body = name+salutation+message
      puts "Sending to #{name} at #{email}"
      SendGMail.send_gmail(:to => email,
                           :subject => subject,
                           :body => body,
                           :password => password,
                           :domain => domain,
                           :from => from,
                           :cc => cc,
                           :user_name => username)
    puts "Messages sent."
  end
  rescue Net::SMTPAuthenticationError, Net::SMTPUnknownError
    puts "Incorrect password"
    tries -= 1
    if(tries>0)
      password=get_password(username)
      retry
    else
      puts "Got 3 incorect passwords. Quitting"
    end
  end
else
  puts "OK, exiting without sending"
end
