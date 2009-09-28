# I took this script from 
# http://codingfrenzy.alexpmay.com/2007/12/sending-gmail-from-standalone-ruby.html
# and made a few slight modifications to allow 
# me to pass in the username/password instead of hardcoding them

require 'rubygems'
gem 'actionmailer'
require 'action_mailer'
require 'openssl'
require 'net/smtp'

module SendGMail

  def SendGMail.send_gmail(hsh)

    @user_name = hsh[:user_name]
    @domain = hsh[:domain]
    @password = hsh[:password]

    ActionMailer::Base.smtp_settings = {
      :address => 'smtp.gmail.com',
      :domain => @domain,
      :authentication => :plain,
      :port => 587,
      :user_name => @user_name,
      :password => @password
    }

    raw_attachments=hsh.fetch(:raw_attachements, [])
    if hsh.has_key?(:raw_attachment)
      raw_attachments.push(hsh[:raw_attachment])
    end

    mail=TMail::Mail.new
    mail.to=hsh[:to]
    mail.date=Time.now
    mail.from = hsh[:from]
    mail.cc = hsh[:cc]
    mail.bcc = hsh[:bcc]
    mail.subject=hsh[:subject]

    main=mail
    main=TMail::Mail.new
    main.body = hsh[:body]
    main.set_content_type('text/plain', nil, 'charset'=>'utf-8')
    mail.parts.push(main)

    for raw_attachment in raw_attachments
      part = TMail::Mail.new
      transfer_encoding=raw_attachment[:transfer_encoding]
      body=raw_attachment[:body]
      case (transfer_encoding || "").downcase
      when "base64" then
        part.body = TMail::Base64.folding_encode(body)
      when "quoted-printable"
        part.body = [body].pack("M*")
      else
        part.body = body
      end
      
      part.transfer_encoding = transfer_encoding
      part.set_content_type(raw_attachment[:mime_type], nil, 'name' => raw_attachment[:filename])
      part.set_content_disposition("attachment", "filename"=>raw_attachment[:filename])
      mail.parts.push(part)
    end

    mail.set_content_type('multipart', 'mixed') 
    ActionMailer::Base.deliver(mail)

  end

  Net::SMTP.class_eval do
    private
    def do_start(helodomain, user, secret, authtype)
      raise IOError, 'SMTP session already started' if @started
      check_auth_args user, secret if user or secret

      sock = timeout(@open_timeout) { TCPSocket.open(@address, @port) }
      @socket = Net::InternetMessageIO.new(sock)
      @socket.read_timeout = 60 #@read_timeout
      @socket.debug_output = STDERR #@debug_output

      check_response(critical { recv_response() })
      do_helo(helodomain)

      raise 'openssl library not installed' unless defined?(OpenSSL)
      starttls
      ssl = OpenSSL::SSL::SSLSocket.new(sock)
      ssl.sync_close = true
      ssl.connect
      @socket = Net::InternetMessageIO.new(ssl)
      @socket.read_timeout = 60 #@read_timeout
      @socket.debug_output = STDERR #@debug_output
      do_helo(helodomain)

      authenticate user, secret, authtype if user
      @started = true
    ensure
      unless @started
        # authentication failed, cancel connection.
        @socket.close if not @started and @socket and not @socket.closed?
        @socket = nil
      end
    end

    def do_helo(helodomain)
      begin
        if @esmtp
          ehlo helodomain
        else
          helo helodomain
        end
      rescue Net::ProtocolError
        if @esmtp
          @esmtp = false
          @error_occured = false
          retry
        end
        raise
      end
    end

    def starttls
      getok('STARTTLS')
    end

    def quit
      begin
        getok('QUIT')
      rescue EOFError, OpenSSL::SSL::SSLError
      end
    end
  end
end

