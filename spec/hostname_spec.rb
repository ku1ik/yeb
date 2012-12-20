require 'spec_helper'
require 'yeb/hostname'

describe Yeb::Hostname do
  let(:hostname) { Yeb::Hostname.new('bar.foo.dev') }

  describe '.from_http_request' do
    let(:host) { 'foobar.baz' }

    let(:request) do
      <<EOS
GET / HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate, compress
Host: #{host}
User-Agent: HTTPie/0.3.0
EOS
    end

    subject { Yeb::Hostname.from_http_request(request) }

    it { should be_kind_of(Yeb::Hostname) }
    its(:name) { should == host }
  end

  describe '#root' do
    subject { hostname.root }

    it { should be_kind_of(Yeb::Hostname) }

    context 'for .dev hostname' do
      let(:hostname) { Yeb::Hostname.new('foo.bar.dev') }

      its(:name) { should == 'bar.dev' }

      context 'for root domain' do
        let(:hostname) { Yeb::Hostname.new('bar.dev') }

        it { should be(hostname) }
      end
    end

    context 'for .lvh.me hostname' do
      let(:hostname) { Yeb::Hostname.new('bar.baz.lvh.me') }

      its(:name) { should == 'baz.lvh.me' }

      context 'for root domain' do
        let(:hostname) { Yeb::Hostname.new('baz.lvh.me') }

        it { should be(hostname) }
      end
    end

    context 'for .xip.io hostname' do
      let(:hostname) { Yeb::Hostname.new('baz.inga.192.168.1.1.xip.io') }

      its(:name) { should == 'inga.192.168.1.1.xip.io' }

      context 'for root domain' do
        let(:hostname) { Yeb::Hostname.new('inga.192.168.1.1.xip.io') }

        it { should be(hostname) }
      end
    end
  end

  describe '#app_name' do
    subject { hostname.app_name }

    context 'for .dev hostname' do
      let(:hostname) { Yeb::Hostname.new('foo.bar.dev') }

      it { should == 'foo.bar' }
    end

    context 'for .lvh.me hostname' do
      let(:hostname) { Yeb::Hostname.new('bar.baz.lvh.me') }

      it { should == 'bar.baz' }
    end

    context 'for .xip.io hostname' do
      let(:hostname) { Yeb::Hostname.new('baz.inga.192.168.1.1.xip.io') }

      it { should == 'baz.inga' }
    end
  end

  describe '#to_s' do
    subject { hostname.to_s }

    it { should == hostname.name }
  end
end
