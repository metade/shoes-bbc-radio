Shoes.setup do
  gem 'memoize'
  gem 'xmpp4r'
  gem 'json_pure'
  gem 'mime-types'
  gem 'activerdf'
  gem 'activerdf_rdflite'
end

# TODO: remove this once xmpp4r launched with hellomatty's patches
$:.unshift '/usr/local/lib/ruby/site_ruby/1.8/'
# TODO: remove this once Shoes supports openssl
require '/usr/local/lib/ruby/1.8/openssl.rb'

require 'lib/nowplaying'

class ShoesRadio < Shoes
  url '/', :index
  url '/listen/(\w+)', :listen
  
  SERVICES = {
    'radio1' => 'http://www.bbc.co.uk/radio1/wm_asx/aod/radio1.asx',
    '6music' => 'http://www.bbc.co.uk/6music/ram/6music.asx',
  }
    
  def index
    list_services
  end
    
  def listen(service)
    stack :margin => 4, :height => 10 do
      @vid = video(SERVICES[service])
    end
    para "#{service}: ",
      link("play") { @vid.play; @label.replace('about to play...') }, ", ",
      link("stop") { @vid.stop; @label.replace('about to stop...') }
    @label = para @vid.playing?    
    animate(1) { @label.replace((@vid.playing?) ? 'playing' : 'stopped') }
    
    stack :margin => 4 do
      @episode_name = para ''
      @wikipedia_url = link('Wikipedia link')
      @long_synopsis = para ''
    end
    
    begin
      @onnow_listener = OnNow.new(service)
      @onnow_listener.listen do |data|
        @episode_name.replace data[:episode_name]
        @long_synopsis.replace data[:long_synopsis]
        @wikipedia_url.replace data[:wikipedia_url]
      end
    rescue Exception => e
      @logger.error e.message
      @logger.error e.backtrace.join("\n")
    end
  end

  private
  
  def list_services(current=nil)
    SERVICES.keys.each do |s| 
      para( (s==current) ? s : link(s, :click => "/listen/#{s}") )
    end    
  end
end

Shoes.app :title => "Shoes BBC Radio", :width => 300, :height => 500, :radius => 12, :resizable => true
