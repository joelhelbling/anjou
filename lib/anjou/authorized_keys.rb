require 'net/http'
require 'json'

module Anjou
  class AuthorizedKeys
    attr_reader :keys

    def initialize(github_username)
      uri = URI.parse("https://api.github.com/users/#{github_username}/keys")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      data = http.get(uri.request_uri)
      @keys = JSON.parse data.body
    end

    def contents
      @keys.map{|item| item['key']}.join("\n")
    end

  end
end


