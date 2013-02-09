require File.expand_path('../spec_helper', __FILE__)

describe Rack::SSIProcessor do
  
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
     
      ssi = Rack::SSIProcessor.new
      blocks = []

      processed = ssi.process_block(html) {|block| blocks << block}

      processed.gsub(/\s+/, "").should == expected
      blocks.should == [["shush", ""], ["shouty", "<h1>ERROR!</h1>"]]      
    end
    it "should yield block directives and strip them out of the html from HAML responses" do
      html = <<-eos
        <html>
          <body>
            <!-- # block name="shush" --><!-- # endblock -->
            <p>some content</p>
            <!-- #block name="shouty" --><h1>ERROR!</h1><!-- # endblock -->
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
     
      ssi = Rack::SSIProcessor.new
      blocks = []

      processed = ssi.process_block(html) {|block| blocks << block}

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
     
        ssi = Rack::SSIProcessor.new
        ssi.stub(:fetch).with("/some/location").and_return([200, {}, "<p>some content</p>"])
        ssi.stub(:fetch).with("/some/other/location").and_return([200, {}, "<p>some more content</p>"])

        processed = ssi.process_include(html, {})

        processed.gsub(/\s+/, "").should == expected
      end
      it "should replace include directives from HAML response with appropriate content" do
        html = <<-eos
          <html>
            <body>
              <!-- # include virtual="/some/other/location_from_haml" -->
              <!-- #include virtual="/some/other/location_from_haml" -->
            </body>
          </html>
        eos
      
        expected = <<-eos.gsub /\s+/, ""
          <html>
            <body>
              <p>some content from haml</p>
              <p>some content from haml</p>
            </body>
          </html>
        eos
     
        ssi = Rack::SSIProcessor.new
        ssi.stub(:fetch).with("/some/other/location_from_haml").and_return([200, {}, "<p>some content from haml</p>"])

        processed = ssi.process_include(html, {})

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
     
        ssi = Rack::SSIProcessor.new
        ssi.stub(:fetch).with("/some/broken/location").and_return([200, {}, ""])

        processed = ssi.process_include(html, {"oops" => "<p>oops, something went wrong!</p>"})

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
        
        ssi = Rack::SSIProcessor.new
        ssi.stub(:fetch).with("/some/broken/location").and_return([200, {}, ""])

        processed = ssi.process_include(html, {})

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
     
        ssi = Rack::SSIProcessor.new
        ssi.stub(:fetch).with("/some/broken/location").and_return([500, {}, "<crap>"])

        processed = ssi.process_include(html, {"oops" => "<p>oops, something went wrong!</p>"})

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
        
        ssi = Rack::SSIProcessor.new
        ssi.stub(:fetch).with("/some/broken/location").and_return([500, {}, "<bang>"])

        processed = ssi.process_include(html, {})

        processed.gsub(/\s+/, "").should == "<html><body><bang></body></html>"
      end
    end
    
  end
  
  describe "#fetch" do
    it "should resolve locations by exact match first" do
      ssi = Rack::SSIProcessor.new
      ssi.locations = {
        /\/pants/ => "http://host1",
        "/pants" => "http://host2"
      }
      
      RestClient.should_receive(:get).with("http://host2/pants")
      ssi.fetch("/pants")      
    end
    
    it "should resolve locations by regex if no exact match" do
      ssi = Rack::SSIProcessor.new
      ssi.locations = {
        /^\/pants\/.*/ => "http://host1",
        "/pants" => "http://host2"
      }
      
      RestClient.should_receive(:get).with("http://host1/pants/on/fire")
      ssi.fetch("/pants/on/fire")      
    end
  end
  
  describe "#process" do
    it "should do it all!" do
      body = [
        '<html><body>',
        '<!--# block name="shouty" --><p>ERROR!</p><!--# endblock -->',
        '<!--# include virtual="/includes/broken" stub="shouty" -->',
        '<!--# include virtual="/includes/header" -->',
        '</body></html>'
      ]
      ssi = Rack::SSIProcessor.new
      ssi.stub(:fetch).with("/includes/broken").and_return([500, {}, "<p>pants!</p>"])
      ssi.stub(:fetch).with("/includes/header").and_return([200, {}, "<h1>Hello</h1>"])
      
      ssi.process(body).join.should == "<html><body><p>ERROR!</p><h1>Hello</h1></body></html>"
    end
  end
  
end
