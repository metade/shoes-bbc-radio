Shoes.setup do
  # gem 'xmpp4r'
end
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
    animate(1) { @label.replace @vid.playing? ? 'playing' : 'stopped' }
    
    @logger.info('creating listen')
    begin
      @nowplaying = NowPlaying.new(service)
    rescue Exception => e
      @logger.error e.message
      @logger.error e.backtrace.join("\n")
    end
    @logger.info('listening')
    @nowplaying.listen do |stuff|
      @logger.info stuff
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
