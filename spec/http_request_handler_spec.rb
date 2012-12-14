require 'spec_helper'

describe Yeb::HTTPRequestHandler do
  let(:handler) { Yeb::HTTPRequestHandler.new }

  describe '#get_response' do
    let(:request_body) do
      <<EOS
GET / HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate, compress
Host: lulu.dev
User-Agent: HTTPie/0.3.0
EOS
    end

    subject { handler.get_response(request_body) }

    it 'looks up app by hostname' do

    end
  end
end
