require File.expand_path('../spec_helper', __FILE__)

describe Rack::SSI do
  describe "#call" do

    it "should not process response if the when predicate returns false" do
      app = double
      body = ["I am a response"]      
      app.stub(:call).and_return([200, {"Content-Type" => ["text/html"]}, body])
      rack_ssi = Rack::SSI.new(app, :when => lambda {|env| false })
      
      Rack::SSIProcessor.any_instance.should_not_receive(:process).and_return([""])
      
      rack_ssi.call({})
    end

    it "should process response if the when predicate returns true" do
      app = double
      body = ["I am a response"]      
      app.stub(:call).and_return([200, {"Content-Type" => ["text/html"]}, body])
      rack_ssi = Rack::SSI.new(app, :when => lambda {|env| true })
      
      Rack::SSIProcessor.any_instance.should_receive(:process).with(body).once.and_return([""])
      
      rack_ssi.call({})
    end
  
    it "should process html responses only" do
      app = double
      body = ["I am a response"]      
      app.stub(:call).and_return(
        [200, {"Content-Type" => ["text/html"]}, body],
        [200, {"Content-Type" => ["text/css"]}, []])
      rack_ssi = Rack::SSI.new(app)
      
      Rack::SSIProcessor.any_instance.should_receive(:process).with(body).once.and_return([""])      
      
      rack_ssi.call({})
    end
    
    it "should process 200 responses only" do
      app = double
      body = ["I am a response"]      
      app.stub(:call).and_return(
        [200, {"Content-Type" => ["text/html"]}, body],
        [500, {"Content-Type" => ["text/html"]}, []])
      rack_ssi = Rack::SSI.new(app)
      
      Rack::SSIProcessor.any_instance.should_receive(:process).with(body).once.and_return([""])      
      
      rack_ssi.call({})
    end
    
    it "should return the processed response and update the Content-Length header" do
      body = ["I am a response"]
      app = double(:call => [200, {"Content-Type" => ["text/html"], "Content-Length" => "15"}, body])
      rack_ssi = Rack::SSI.new(app)
      Rack::SSIProcessor.any_instance.stub(:process => ["I am a bigger response"])
      
      _, headers, new_body = rack_ssi.call({})
      
      new_body.should == ["I am a bigger response"]
      headers["Content-Length"].should == "22"
    end
  
  end
  
end