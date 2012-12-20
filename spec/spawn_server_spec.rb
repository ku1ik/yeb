require 'spec_helper'
require 'yeb/spawn_server'

describe Yeb::SpawnServer do
  let(:socket_path) { '/tmp/.yeb-test.sock' }
  let(:apps_dir) { Dir.mktmpdir }
  let(:sockets_dir) { Dir.mktmpdir }
  let(:server) { Yeb::SpawnServer.new(socket_path, apps_dir, sockets_dir) }

  before { FileUtils.rm_rf(socket_path) }

  describe '#listen' do
    before do
      Socket.stub!(:accept_loop => nil)
    end

    it 'creates new UNIXServer with proper path' do
      server.listen
      File.exist?(socket_path).should be(true)
    end

    it 'removes stale socket file' do
      FileUtils.touch(socket_path)
      old_inode = File.stat(socket_path).ino
      server.listen
      new_inode = File.stat(socket_path).ino
      new_inode.should_not == old_inode
    end

    it 'calls Socket.accept_loop with server socket' do
      socket = double('socket')
      UNIXServer.should_receive(:new).and_return(socket)
      Socket.should_receive(:accept_loop).with(socket)
      server.listen
    end

    it 'uses HTTPRequestHandler to generate response' do
      client_socket = double('client_socket')
      addr = double('addr')
      Socket.should_receive(:accept_loop).and_yield(client_socket, addr)

      request_body = double('request_body')
      client_socket.should_receive(:recv).and_return(request_body)

      handler = double('HTTPRequestHandler')
      response = double('response').to_s
      handler.stub!(:get_response => response)
      Yeb::HTTPRequestHandler.should_receive(:new).and_return(handler)

      client_socket.should_receive(:send).with(response, 0)
      client_socket.should_receive(:close)

      server.listen
    end
  end
end
