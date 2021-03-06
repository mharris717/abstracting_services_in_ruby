# !SLIDE :capture_code_output true
# Socket service with local fallback.

require 'example_helper'
begin
  File.unlink(service_log = "#{__FILE__}.service.log") rescue nil
  Email.asir.transport = t =
    ASIR::Transport::Fallback.new(:transports => [
      tcp = ASIR::Transport::TcpSocket.new(:port => 31911,
                                           :encoder => ASIR::Coder::Marshal.new),
      ASIR::Transport::Broadcast.new(:transports => [
        file = ASIR::Transport::File.new(:file => service_log,
                                         :encoder => ASIR::Coder::Yaml.new(:yaml_options => { :ASCII_8BIT_ok => true })),
        ASIR::Transport::Local.new,
      ]),
    ])
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user@email.com", :customer => @customer)
  server_process do
    tcp.prepare_server!
    tcp.run_server!
  end
  pr Email.asir.send_email(:pdf_invoice,
                             :to => "user2@email.com", :customer => @customer)
ensure
  file.close rescue nil;
  tcp.close rescue nil; sleep 1; server_kill
  puts "\x1a\n#{service_log.inspect} contents:"
  puts File.read(service_log)
end

# !SLIDE END
# EXPECT: : client process
# EXPECT: : server process
# EXPECT/: : Email.send_mail :pdf_invoice .*:to=>"user@email.com"
# EXPECT/: : Email.send_mail :pdf_invoice .*:to=>"user2@email.com"
# EXPECT: : pr: :ok
# EXPECT: service.log" contents:
# EXPECT: --- !ruby/object:ASIR::Message
# EXPECT:   :transport_exceptions:
# EXPECT: Cannot connect to ASIR::Transport::TcpSocket tcp://127.0.0.1:
# EXPECT: arguments:
# EXPECT: - :pdf_invoice
# EXPECT/: :to: user@email.com
# EXPECT/: :customer: 123
# EXPECT: receiver: Email
# EXPECT: receiver_class: Module
# EXPECT: selector: :send_email
