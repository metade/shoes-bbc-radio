require 'rubygems'

require 'xmpp4r'
require 'xmpp4r/pubsub'
require 'base64'

require 'active_rdf'
require 'open3'
require 'pp'

require 'memoize'

module Jabber
  class Client
    attr_writer :jid
  end
end
 
class OnNow
  include Jabber
  include Memoize

  Namespace.register 'po', 'http://purl.org/ontology/po/'
  Namespace.register 'foaf', 'http://xmlns.com/foaf/0.1/'
  Namespace.register 'dc', 'http://purl.org/dc/elements/1.1/'
  Namespace.register 'dbp', 'http://dbpedia.org/property/'

  def initialize(service)
    # set up xmpp
    client = Jabber::Client.new Jabber::JID.new( nil, 'public.hug.hellomatty.com' )
    client.connect 
    client.auth_anonymous_sasl
    client.send_with_id Jabber::Presence.new do |response|
      client.jid = response.to
    end
    Jabber::debug = false
    @sub = Jabber::PubSub::ServiceHelper.new( client, 'pubsub.hug.hellomatty.com' )
    @sub.subscribe_to "/home/hug.hellomatty.com/#{service}/onnow"
    
    # set up rdf store
    @adapter = ConnectionPool.add_data_source :type => :fetching
    @adapter.add_ntriples(File.read('data/foaf_homepages.nt'), nil)
    # @sparql_adapter = ConnectionPool.add_data_source( #SparqlAdapter.new(
    #   :type => :sparql, 
    #   :url => 'http://dbpedia.org/sparql', 
    #   :engine => :virtuoso) 
      
    memoize :dbpedia_ifp     
  end
  
  def listen(&block)
    @sub.add_event_callback do |event|
      event.elements.each("/event/items/item/entry/onnow") do |rdf|
        @adapter.add_ntriples(convert_to_ntriple(rdf.text), nil)
      end
      yield process_rdf
    end
  end

  private
  
  def latest_episode    
    q = Query.new
    q.select(:episode)
    q.where(:episode, PO::version, :version)
    q.where(:broadcast, PO::broadcast_of, :version)
    q.where(:broadcast, PO::schedule_date, :schedule_date)
    q.sort(:schedule_date)
    
    q.execute.last
  end
  
  def dbpedia_ifp(property, resource)
    uri = "http://sindice.com/query/lookup?property=#{property.uri}&object=#{resource.uri}"
    string = open(uri, 'Accept' => 'text/plain').read
    result = string.split("\t")
    result.first
  end
    
  def process_rdf
    # find the current episode
    episode = latest_episode
    
    unless episode.nil?
      # find the brand for the episode 
      brand = episode.po::episode
      brand_homepage = brand.foaf::homepage

      brand_dbpedia_uri = dbpedia_ifp(FOAF::homepage, brand_homepage) unless brand_homepage.nil?
      unless brand_dbpedia_uri.nil?
        # TODO: owl:sameAs should be applied here?    
        brand_dbpedia = RDFS::Resource.new(brand_dbpedia_uri)
        wikipedia_url = brand_dbpedia.foaf::page.uri unless brand_dbpedia.foaf::page.nil?
      end
      
      result = {
        :episode_name  => episode.dc::title,
        :long_synopsis => episode.po::long_synopsis,
        :wikipedia_url => wikipedia_url,
      }
    else    
      {}
    end
  end
  
  def convert_to_ntriple(turtle)
    turtle.gsub!('<http://www.bbc.co.uk/', '<http://bbc-programmes.dyndns.org/')
    Open3.popen3("rapper -q -i turtle - http://bbc.co.uk/programmes") do |stdin, stdout, stderr|
      stdin.puts(turtle)  
      stdin.close
      ntriples = stdout.read
    end
  end

end

# Debug code
if __FILE__ == $0
  on = OnNow.new("radio1")
  on.listen do |stuff|
    p stuff
  end
  Thread.abort_on_exception = true
  Thread.stop
end
