require 'spec_helper'

describe Yeb::HTTPRequestHandler do
  let(:apps_dir) { Dir.mktmpdir }
  let(:sockets_dir) { Dir.mktmpdir }
  let(:handler) { Yeb::HTTPRequestHandler.new(apps_dir, sockets_dir) }

  describe '#get_response' do
    let(:request) { double('request') }
    let(:response) { double('response') }
    let(:hostname) { double('hostname') }
    let(:vhost) { double('vhost') }
    let(:socket) { double('socket') }

    subject { handler.get_response(request) }

    before do
      Yeb::Hostname.stub!(:from_http_request => hostname)
    end

    it 'returns response from VirtualHost socket' do
      # FIX: Violating law of Demeter like a boss
      Yeb::VirtualHost.should_receive(:new).
        with(hostname, apps_dir, sockets_dir).and_return(vhost)
      vhost.should_receive(:socket).and_return(socket)
      socket.should_receive(:send).with(request, 0)
      socket.should_receive(:recv).and_return(response)
      socket.should_receive(:close)
      handler.get_response(request).should == response
    end
  end
end
