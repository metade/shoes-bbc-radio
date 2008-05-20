# TODO: remove this once xmpp4r launched with hellomatty's patches
$:.unshift '/usr/local/lib/ruby/site_ruby/1.8/'

require 'xmpp4r'
require 'xmpp4r/pubsub'
require 'base64'

# TODO: remove this once Shoes supports openssl
require '/usr/local/lib/ruby/1.8/openssl.rb'

module Jabber
  class Client
    attr_writer :jid
  end
end
 
class NowPlaying
  include Jabber

  def initialize(service)
    puts 'foo'
    client = Jabber::Client.new Jabber::JID.new( nil, 'public.hug.hellomatty.com' )
    client.connect 
    client.auth_anonymous_sasl
    client.send_with_id Jabber::Presence.new do |response|
      client.jid = response.to
    end
    Jabber::debug = false
    @sub = Jabber::PubSub::ServiceHelper.new( client, 'pubsub.hug.hellomatty.com' )
    @sub.subscribe_to "/home/hug.hellomatty.com/radio1/onnow"
  end

  def listen(&block)
    @sub.add_event_callback do |event|
      event.elements.each("/event/items/item/entry/onnow") do |rdf|
        yield rdf.text
      end
    end
  end  

end

## Debug code
# np = NowPlaying.new("radio1")
# np.listen do |stuff|
#   p stuff
# end
# Thread.stop
