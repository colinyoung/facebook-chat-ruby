require 'socket'
require 'openssl'

class TCPSocket
  def receive_all
    s = self.recvmsg[0]
    $stdout.puts s
    s
  end
  
  def die(msg=nil)
    self.send(CLOSE_XML, 0)
    $stdout.puts "\n\nClosing stream..."
    s.close

    if msg
      raise msg
    else
      $stdout.puts "Complete."
    end
  end
end

hostname = 'chat.facebook.com'
port = 5222
auth_token = "<YOUR AUTH TOKEN>"

STREAM_XML = '<stream:stream ' << 
  'xmlns:stream="http://etherx.jabber.org/streams" ' <<
  'version="1.0" xmlns="jabber:client" to="chat.facebook.com" ' <<
  'xml:lang="en" xmlns:xml="http://www.w3.org/XML/1998/namespace">'
  
AUTH_XML = '<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" ' <<
    'mechanism="X-FACEBOOK-PLATFORM"></auth>'

CLOSE_XML = '</stream:stream>'

RESOURCE_XML = '<iq type="set" id="3">' <<
  '<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">' <<
  '<resource>fb_xmpp_script</resource></bind></iq>'
  
SESSION_XML = '<iq type="set" id="4" to="chat.facebook.com">' <<
    '<session xmlns="urn:ietf:params:xml:ns:xmpp-session"/></iq>'
    
START_TLS = '<starttls xmlns="urn:ietf:params:xml:ns:xmpp-tls"/>'

socket = TCPSocket.open(hostname, port)

ssl_context = OpenSSL::SSL::SSLContext.new(:TLSv1)
s = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
s.sync_close = true
s.connect

if !s
  raise "Couldn't connect to #{hostname}:#{port}"
end

puts "Connected..."

# Send initial XML
s.sendmsg STREAM_XML
response = s.receive_all

if !response.include? "X-FACEBOOK-PLATFORM"
  die(s, "Not a facebook server.")
end

# Start TLS
s.sendmsg START_TLS
response = s.receive_all

if !response.downcase.include? "proceed"
  die(s, "Server doesn't accept TLS.")
end


# Don't forget to close the stream
die(s)