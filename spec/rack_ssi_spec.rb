describe Rack::SSI do
  describe "#call" do
  
    it "should process html responses only" do
      app = double
      body = ["I am a response"]      
      app.stub(:call).and_return(
        [200, {"Content-Type" => ["text/html"]}, body],
        [200, {"Content-Type" => ["text/css"]}, []])
      rack_ssi = Rack::SSI.new(app)
      
      rack_ssi.should_receive(:process).with(body).once.and_return([""])      
      
      rack_ssi.call({})
    end
    
    it "should process 200 responses only" do
      app = double
      body = ["I am a response"]      
      app.stub(:call).and_return(
        [200, {"Content-Type" => ["text/html"]}, body],
        [500, {"Content-Type" => ["text/html"]}, []])
      rack_ssi = Rack::SSI.new(app)
      
      rack_ssi.should_receive(:process).with(body).once.and_return([""])      
      
      rack_ssi.call({})
    end
    
    it "should return the processed response and update the Content-Length header" do
      body = ["I am a response"]
      app = double(:call => [200, {"Content-Type" => ["text/html"], "Content-Length" => "15"}, body])
      rack_ssi = Rack::SSI.new(app)
      rack_ssi.stub(:process => ["I am a bigger response"])
      
      _, headers, new_body = rack_ssi.call({})
      
      new_body.should == ["I am a bigger response"]
      headers["Content-Length"].should == "22"
    end
  
  end
  
  describe "#process_block" do
    it "should yield block directives and strip them out of the html" do
      html = <<-eos
        <html>
          <body>
            <!--# block name="shush" --><!--# endblock -->
            <p>some content</p>
            <!--# block name="shouty" --><h1>ERROR!</h1><!--# endblock -->
          </body>
        </html>
      eos
      
      expected = <<-eos.gsub /\s+/, ""
        <html>
          <body>
            <p>some content</p>
          </body>
        </html>
      eos
     
      rack_ssi = Rack::SSI.new(nil)
      blocks = []

      processed = rack_ssi.process_block(html) {|block| blocks << block}

      processed.gsub(/\s+/, "").should == expected
      blocks.should == [["shush", ""], ["shouty", "<h1>ERROR!</h1>"]]      
    end
  end
  
  describe "#process_include" do
    context "the SSI include request returns a valid response" do
      it "should replace include directives with appropriate content" do
        html = <<-eos
          <html>
            <body>
              <!--# include virtual="/some/location" -->
              <!--# include virtual="/some/other/location" -->
            </body>
          </html>
        eos
      
        expected = <<-eos.gsub /\s+/, ""
          <html>
            <body>
              <p>some content</p>
              <p>some more content</p>
            </body>
          </html>
        eos
     
        rack_ssi = Rack::SSI.new(nil)
        rack_ssi.stub(:fetch).with("/some/location").and_return([200, {}, "<p>some content</p>"])
        rack_ssi.stub(:fetch).with("/some/other/location").and_return([200, {}, "<p>some more content</p>"])

        processed = rack_ssi.process_include(html, {})

        processed.gsub(/\s+/, "").should == expected
      end
    end
    
    context "the SSI include request returns an empty response" do
      it "should replace include directives with the content of the block specified by the 'stub' parameter" do
        html = <<-eos
          <html>
            <body>
              <!--# include virtual="/some/broken/location" stub="oops" -->
            </body>
          </html>
        eos
      
        expected = <<-eos.gsub /\s+/, ""
          <html>
            <body>
              <p>oops, something went wrong!</p>
            </body>
          </html>
        eos
     
        rack_ssi = Rack::SSI.new(nil)
        rack_ssi.stub(:fetch).with("/some/broken/location").and_return([200, {}, ""])

        processed = rack_ssi.process_include(html, {"oops" => "<p>oops, something went wrong!</p>"})

        processed.gsub(/\s+/, "").should == expected
      end
      
      it "should replace include directives with the empty response if no 'stub' parameter" do
        html = <<-eos
          <html>
            <body>
              <!--# include virtual="/some/broken/location" -->
            </body>
          </html>
        eos
        
        rack_ssi = Rack::SSI.new(nil)
        rack_ssi.stub(:fetch).with("/some/broken/location").and_return([200, {}, ""])

        processed = rack_ssi.process_include(html, {})

        processed.gsub(/\s+/, "").should == "<html><body></body></html>"
      end
    end
    
    context "the SSI include request returns an error response" do
      it "should replace include directives with the content of the block specified by the 'stub' parameter" do
        html = <<-eos
          <html>
            <body>
              <!--# include virtual="/some/broken/location" stub="oops" -->
            </body>
          </html>
        eos
      
        expected = <<-eos.gsub /\s+/, ""
          <html>
            <body>
              <p>oops, something went wrong!</p>
            </body>
          </html>
        eos
     
        rack_ssi = Rack::SSI.new(nil)
        rack_ssi.stub(:fetch).with("/some/broken/location").and_return([500, {}, "<crap>"])

        processed = rack_ssi.process_include(html, {"oops" => "<p>oops, something went wrong!</p>"})

        processed.gsub(/\s+/, "").should == expected
      end
      
      it "should replace include directives with the error response if no 'stub' parameter" do
        html = <<-eos
          <html>
            <body>
              <!--# include virtual="/some/broken/location" -->
            </body>
          </html>
        eos
        
        rack_ssi = Rack::SSI.new(nil)
        rack_ssi.stub(:fetch).with("/some/broken/location").and_return([500, {}, "<bang>"])

        processed = rack_ssi.process_include(html, {})

        processed.gsub(/\s+/, "").should == "<html><body><bang></body></html>"
      end
    end
    
  end
  
  describe "#fetch" do
    it "should resolve locations by exact match first" do
      rack_ssi = Rack::SSI.new(nil, {
        :locations => {
          /\/pants/ => "http://host1",
          "/pants" => "http://host2"
        }
      })
      RestClient.should_receive(:get).with("http://host2/pants")
      rack_ssi.fetch("/pants")      
    end
    
    it "should resolve locations by regex if no exact match" do
      rack_ssi = Rack::SSI.new(nil, {
        :locations => {
          /^\/pants\/.*/ => "http://host1",
          "/pants" => "http://host2"
        }
      })
      RestClient.should_receive(:get).with("http://host1/pants/on/fire")
      rack_ssi.fetch("/pants/on/fire")      
    end
  end
  
  describe "#process" do
    it "should do it all!" do
      app = double
      body = [
        '<html><body>',
        '<!--# block name="shouty" --><p>ERROR!</p><!--# endblock -->',
        '<!--# include virtual="/includes/broken" stub="shouty" -->',
        '<!--# include virtual="/includes/header" -->',
        '</body></html>'
      ]
      rack_ssi = Rack::SSI.new(app)
      rack_ssi.stub(:fetch).with("/includes/broken").and_return([500, {}, "<p>pants!</p>"])
      rack_ssi.stub(:fetch).with("/includes/header").and_return([200, {}, "<h1>Hello</h1>"])
      
      rack_ssi.process(body).join.should == "<html><body><p>ERROR!</p><h1>Hello</h1></body></html>"
    end
  end
  
end