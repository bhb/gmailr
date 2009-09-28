require 'rubygems'
require 'highline/import'
require 'send_gmail'
require 'yaml'
require 'erb'

# For instructions on configuring gmailer, see the 'Settings' 
# section below

##### Helper methods #####

def get_password(username)
  password = ask("password for #{username}:") { |q| q.echo = false }
  password
end

def load_config(filename)
  raw_config = File.read(filename)
  erb_config = ERB.new(raw_config).result
  config = YAML.load(erb_config)
  config
end

def convert_recipients(array_of_hashes)
  array_of_hashes.inject({}) do |new_hash, hsh|
    new_hash[hsh['email']] = hsh['name']
    new_hash
  end
end

####### Init ##############

tries = 3
begin
  config_file = ask("config file: ").chomp
  config = load_config(config_file)
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

######## Settings ########

# You should set up your config in a YAML file
# The YAML file can use ERB

# This field must be your Gmail account
username = config['username']

# This can be another email address
from = config['from']

# This should stay the same
domain = "gmail.com"

# Add any addresses you would like CCed
# YAML will look like:
# cc: [address1, address2]
cc = config['cc'].join(", ")

subject = config['subject']

# Fill this hash with email addresses and salutations. 
# The YAML should look like
# to:
#   - name: John
#     email: john@doe.com
#   - name: Dr. Smith
#     email: sally@ssmith.com
to = convert_recipients(config['to'])

########################

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
      body = nil
      if(name.to_s.empty?)
        body = message
      else
        body = name+salutation+message
      end
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
