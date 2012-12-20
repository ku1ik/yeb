require 'spec_helper'
require 'tempfile'
require 'yeb/virtual_host'

describe Yeb::VirtualHost do
  let(:apps_dir) { Dir.mktmpdir }
  let(:sockets_dir) { Dir.mktmpdir }
  let(:hostname) { Yeb::Hostname.new('foo.dev') }
  let(:vhost) { Yeb::VirtualHost.new(hostname, apps_dir, sockets_dir) }

  def symlink_target(hostname)
    "#{apps_dir}/#{hostname.name}".sub(/\.dev$/, '')
  end

  describe '#app_symlink_path' do
    subject { vhost.app_symlink_path }

    let(:hostname) { Yeb::Hostname.new('foo.bar.dev') }

    context 'when app symlinked in apps_dir' do
      before do
        File.symlink('/tmp/app', symlink_target(hostname))
      end

      it { should == "#{apps_dir}/foo.bar" }
    end

    context 'when no app symlinked in apps_dir' do
      it { should == nil }

      context 'when root app symlinked in apps_dir' do
        before do
          File.symlink('/tmp/app', symlink_target(hostname.root))
        end

        it { should == "#{apps_dir}/bar" }
      end
    end
  end

  describe '#app_real_path' do
    subject { vhost.app_real_path }

    context 'when app_symlink_path is present' do
      let(:real_path) do
        file = Tempfile.new('real_path')
        file.close
        file.path
      end

      let(:double_symlink_path) do
        File.symlink(real_path, "#{real_path}.1")
        File.symlink("#{real_path}.1", "#{real_path}.2")
        "#{real_path}.2"
      end

      before do
        vhost.stub!(:app_symlink_path => double_symlink_path)
      end

      it { should == real_path }
    end

    context 'when app_symlink_path is not present' do
      before do
        vhost.stub!(:app_symlink_path => nil)
      end

      it { should be(nil) }
    end
  end

  describe '#app_name' do
    subject { vhost.app_name }

    context 'when app_symlink_path is present' do
      before do
        vhost.stub!(:app_symlink_path => '/a/b/c')
      end

      it { should == 'c' }
    end

    context 'when app_symlink_path is not present' do
      before do
        vhost.stub!(:app_symlink_path => nil)
      end

      it { should be(nil) }
    end
  end

  describe '#socket_path' do
    subject { vhost.socket_path }

    let(:app_name) { double }

    before do
      hostname.stub!(:app_name => app_name.to_s)
    end

    it { should == "#{sockets_dir}/#{app_name}.sock" }
  end

  describe '#app_socket_path' do
    subject { vhost.app_socket_path }

    context 'when app_real_path is present' do
      before do
        vhost.stub!(:app_real_path => '/a/b/c')
      end

      it { should =~ %r(^#{sockets_dir}/.+\.sock$) }
    end

    context 'when app_real_path is not present' do
      before do
        vhost.stub!(:app_real_path => nil)
      end

      it { should be(nil) }
    end
  end

  describe '#create_socket_symlink' do
    pending
  end

  describe '#app_symlinked?' do
    subject { vhost.app_symlinked? }

    context 'when app_symlink_path is present' do
      before do
        vhost.stub!(:app_symlink_path) { '/some' }
      end

      it { should be(true) }
    end

    context 'when app_symlink_path is not present' do
      before do
        vhost.stub!(:app_symlink_path) { nil }
      end

      it { should be(false) }
    end
  end

  describe '#socket' do
    pending
  end

  describe '#spawn_app' do
    let(:app_name) { double('app_name') }
    let(:dir) { double('dir') }
    let(:socket_path) { double('socket_path') }
    let(:app) { double('app') }

    it 'creates new instance of RackApp and calls #spawn on it' do
      vhost.stub!(:app_name => app_name, :app_real_path => dir, :app_socket_path => socket_path)
      Yeb::RackApp.should_receive(:new).with(app_name, dir, socket_path).and_return(app)
      app.should_receive(:spawn)

      vhost.spawn_app
    end
  end
end
