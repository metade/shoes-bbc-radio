require File.join(File.dirname(__FILE__), '..', 'lib', 'nowplaying')

describe OnNow do
  before(:each) do
    @onnow = OnNow.new('radio1')
  end
  
  it "should process rdf and return an empty hash when given empty string" do
    @onnow.send(:process_rdf, '').should == {}
  end

  it "should return the dbpedia uri for a given show" do
    resource = RDFS::Resource.new('http://www.bbc.com/radio1/colinmurray')
    uri = @onnow.send(:dbpedia_ifp, FOAF::homepage, resource)
    uri.should == 'http://dbpedia.org/resource/Colin_Murray'
  end
    
  describe "processing onnow rdf" do 
    before(:each) do
      rdf = load_rdf 'colin_murray.n3'
      @result = @onnow.send(:process_rdf, rdf)
    end

    it "should determine the episode title" do
      @result[:episode_name].should == 'Colin Murray'
    end

    it "should determine the Wikipedia link" do
      @result[:wikipedia_url].should == 'http://en.wikipedia.org/wiki/Colin_Murray'
    end

    describe "should process another rdf file from an earlier show" do 
      before(:each) do
        rdf = load_rdf 'zane_lowe.n3'
        @new_result = @onnow.send(:process_rdf, rdf) 
      end

      it "and determine the latest episode title" do
        @new_result[:episode_name].should == 'Colin Murray'
      end
    end
  
  
  end
  
end

def load_rdf(name)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', 'rdf', name))
end