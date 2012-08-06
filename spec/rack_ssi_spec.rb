describe Rack::SSI do
  describe "#call" do
  
    it "should process html responses" do
      app = double(:call => [200, {"Content-Type" => ["text/html"]}, []])
      rack_ssi = Rack::SSI.new(app)
      rack_ssi.call({})
      rack_ssi.should_receive(:process)      
    end
    
    # it "should update the ContentLength header if modifying the body" do
    #   
    # end
  
  end
end