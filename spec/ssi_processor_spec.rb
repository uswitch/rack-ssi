# encoding: UTF-8

require File.expand_path('../spec_helper', __FILE__)

describe Rack::SSIProcessor do
  let(:env) { double('env', :[] => '') }
  let(:instance) { described_class.new(env, logger, options) }
  let(:logger) {}
  let(:options) { {headers: ->(*) { {} }, locations: locations} }
  let(:locations) { {} }

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

      blocks = []

      processed = instance.process_block(html) {|block| blocks << block}

      expect(processed.gsub(/\s+/, "")).to eq expected
      expect(blocks).to eq [["shush", ""], ["shouty", "<h1>ERROR!</h1>"]]
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

      blocks = []

      processed = instance.process_block(html) {|block| blocks << block}

      expect(processed.gsub(/\s+/, "")).to eq expected
      expect(blocks).to eq [["shush", ""], ["shouty", "<h1>ERROR!</h1>"]]
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

        allow(instance).to receive(:fetch).with("/some/location").and_return([200, {}, "<p>some content</p>"])
        allow(instance).to receive(:fetch).with("/some/other/location").and_return([200, {}, "<p>some more content</p>"])

        processed = instance.process_include(html, {})

        expect(processed.gsub(/\s+/, "")).to eq expected
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

        allow(instance).to receive(:fetch).with("/some/other/location_from_haml").and_return([200, {}, "<p>some content from haml</p>"])

        processed = instance.process_include(html, {})

        expect(processed.gsub(/\s+/, "")).to eq expected
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

        allow(instance).to receive(:fetch).with("/some/broken/location").and_return([200, {}, ""])

        processed = instance.process_include(html, {"oops" => "<p>oops, something went wrong!</p>"})

        expect(processed.gsub(/\s+/, "")).to eq expected
      end

      it "should replace include directives with the empty response if no 'stub' parameter" do
        html = <<-eos
          <html>
            <body>
              <!--# include virtual="/some/broken/location" -->
            </body>
          </html>
        eos

        allow(instance).to receive(:fetch).with("/some/broken/location").and_return([200, {}, ""])

        processed = instance.process_include(html, {})

        expect(processed.gsub(/\s+/, "")).to eq "<html><body></body></html>"
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

        allow(instance).to receive(:fetch).with("/some/broken/location").and_return([500, {}, "<crap>"])

        processed = instance.process_include(html, {"oops" => "<p>oops, something went wrong!</p>"})

        expect(processed.gsub(/\s+/, "")).to eq expected
      end

      it "should replace include directives with the error response if no 'stub' parameter" do
        html = <<-eos
          <html>
            <body>
              <!--# include virtual="/some/broken/location" -->
            </body>
          </html>
        eos

        allow(instance).to receive(:fetch).with("/some/broken/location").and_return([500, {}, "<bang>"])

        processed = instance.process_include(html, {})

        expect(processed.gsub(/\s+/, "")).to eq "<html><body><bang></body></html>"
      end
    end

    context "the SSI include request returns a response with a different encoding than the context" do
      it "should force the encoding of the context" do
        html = <<-eos
          <html>
            <body>
              <!--# include virtual="/some/location" -->
            </body>
          </html>
        eos

        expected = <<-eos.gsub /\s+/, ""
          <html>
            <body>
              <p>€254</p>
            </body>
          </html>
        eos

        allow(instance).to receive(:fetch).with("/some/location").and_return([200, {}, "<p>€254</p>".force_encoding("ASCII-8BIT")])

        processed = instance.process_include(html, {})
        expect(processed.gsub(/\s+/, "")).to eq expected
      end
    end
  end

  describe "#fetch" do
    context 'when locations contains mathcing string' do
      let(:locations) { {
        /\/shorts/ => 'http://host1',
        '/pants' => 'http://host2'
      } }

      it 'resolves locations by exact match first' do
        allow(HTTParty).to receive(:get).
          and_return(double('response', code: 200, headers: [], body: ''))
        expect(HTTParty).to receive(:get).with('http://host2/pants', anything)
        instance.fetch('/pants')
      end
    end

    context 'when locations contains matching regex' do
      let(:locations) { {
        /^\/pants\/.*/ => 'http://host1',
        '/pants' => 'http://host2'
      } }

      it 'resolves locations by regex if no exact match' do
        allow(HTTParty).to receive(:get).
          and_return(double('response', code: 200, headers: [], body: ''))
        expect(HTTParty).to receive(:get).with('http://host1/pants/on/fire', anything)
        instance.fetch('/pants/on/fire')
      end
    end

    context 'when matching location provides proc' do
      let(:locations) { {
        /\/pants/ => ->(location) { "http://host1#{location.sub 'ant', 'ub'}"}
      } }

      it 'resolves locations by regex if no exact match' do
        allow(HTTParty).to receive(:get).
          and_return(double('response', code: 200, headers: [], body: ''))
        expect(HTTParty).to receive(:get).with('http://host1/pubs/on/fire', anything)
        instance.fetch('/pants/on/fire')
      end
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
      expect(instance).to receive(:fetch).with("/includes/broken").
        and_return([500, {}, "<p>pants!</p>"])
      expect(instance).to receive(:fetch).with("/includes/header").
        and_return([200, {}, "<h1>Hello</h1>"])

      expect(instance.process(body).join).to eq "<html><body><p>ERROR!</p><h1>Hello</h1></body></html>"
    end
  end
end
