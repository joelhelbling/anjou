require 'anjou/authorized_keys'

module Anjou
  describe AuthorizedKeys do
    let(:gh_user) { 'foogoo' }
    subject { described_class.new(gh_user) }

    let(:key1) { "ssh-rsa AABBCC==" }
    let(:key2) { "ssh-dss AABBCCDD=" }
    let(:key3) { "ssh-rsa ZZYYXX=" }
    let(:gh_response) do
      "[{\"id\":101,\"key\":\"#{key1}\"}," +
       "{\"id\":102,\"key\":\"#{key2}\"}," +
       "{\"id\":103,\"key\":\"#{key3}\"}]"
    end
    let(:expected_authorized_keys) do
      [key1, key2, key3].join("\n")
    end

    let(:data) { double }
    before do
      Net::HTTP.any_instance.stub(:get).and_return(data)
      data.stub(:body).and_return(gh_response)
    end

    its(:keys)     { should have(3).items }
    its(:contents) { should == expected_authorized_keys }
  end
end
