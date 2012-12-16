require 'spec_helper'

describe Yeb::Hostname do
  let(:hostname) { Yeb::Hostname.new('bar.foo.com') }

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

    context 'for root domain' do
      let(:hostname) { Yeb::Hostname.new('foo.com') }

      it { should be(hostname) }
    end

    context 'for subdomain' do
      it { should be_kind_of(Yeb::Hostname) }
      it { should_not be(hostname) }
      its(:name) { should == 'foo.com' }
    end
  end

  describe '#app_name' do
    subject { hostname.app_name }

    it { should == 'bar.foo' }
  end

  describe '#to_s' do
    subject { hostname.to_s }

    it { should == hostname.name }
  end
end
