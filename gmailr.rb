require 'rubygems'
require 'highline/import'
require 'send_gmail'

##### Settings ########

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

########################
########################

def get_password(username)
  password = ask("password for #{username}:") { |q| q.echo = false }
  password
end

tries = 3
begin
  file = ask("file containing message: ").chomp
  message = File.read(file)
rescue Errno::ENOENT
  tries -= 1
  if(tries > 0)
    puts "File not found. Please try again."
    retry
  else
    puts "File not found. Quitting"
    exit
  end
end

salutation = ",\n\n"
puts "To: #{to.map{|k,v| "#{k} (#{v})"}.join(" ,")}"
puts "From: #{from}"
puts "CC: #{cc}"
puts "Subject: #{subject}"
puts "Message:\n[name]#{salutation}#{message}"
continue = ask("Is this message OK? [yes/no]:")
if(continue=="yes")
  password = get_password(username)
  tries = 3
  no_more_retries =  "Got #{tries} incorrect passwords. Quitting"
  begin
    to.each do |email,name|
      body = name+salutation+message
      puts "Sending to #{name} at #{email}"
      begin
        SendGMail.send_gmail(:to => email,
                             :subject => subject,
                             :body => body,
                             :password => password,
                             :domain => domain,
                             :from => from,
                             :cc => cc,
                             :user_name => username)
      rescue Timeout::Error
        puts "Sending message to #{email} timed out. Retrying"
        sleep(3)
        retry
      rescue SocketError
        puts "Cannot reach Gmail. Retrying"
        sleep(3)
        retry
      end
    puts "Messages sent."
  end
  rescue Net::SMTPAuthenticationError, Net::SMTPUnknownError
    puts "Incorrect password"
    tries -= 1
    if(tries>0)
      password=get_password(username)
      retry
    else
      puts no_more_retries
    end
  end
else
  puts "OK, exiting without sending"
end
