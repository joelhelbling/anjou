require 'aws-sdk'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'credentials', 'anjou'))

module Anjou
  class EC2
    attr_reader :api

    KEY_ID        = Anjou::AWS::ACCESS_KEY_ID
    SECRET_KEY    = Anjou::AWS::SECRET_ACCESS_KEY
    USER_VOL_SIZE = 1 #Gb
    DEFAULT_ZONE  = "us-east-1b"

    def initialize(access_key_id=KEY_ID, secret_access_key=SECRET_KEY)
      @api = ::AWS::EC2.new(
        access_key_id:     access_key_id,
        secret_access_key: secret_access_key )
    end

    def create_user_volume(username=nil)
      @api.volumes.create(size: USER_VOL_SIZE, availability_zone: DEFAULT_ZONE).tap do |volume|
        if username
          volume.tags.username = username
        end
      end
    end

    def delete_user_volume(username)
      detach(username).delete
    end

    def user_volume_for(username)
      @api.volumes.tagged('username').select do |vol|
        vol.tags.to_a.include? ['username', username]
      end.first
    end

    def attach(username, instance, device=nil)
      volume = user_volume_for(username)
      guard_volume_available(volume, username)
      device = next_device_for(instance) unless device
      volume.attach_to instance, device
    end

    def detach(username)
      user_volume_for(username).tap do |volume|
        volume.attachments.each do |attachment|
          attachment.delete(force: true)
        end
        sleep 1 until volume.status == :available
      end
    end

    def next_device_for(instance)
      '/dev/sda' + (instance.attachments.keys.size + 1).to_s
    end

    private

    def guard_volume_available(volume, username)
      volume.status.tap do |status|
        unless status == :available
          raise "user volume \"#{username}\" is not available (status: #{status})"
        end
      end
    end
  end
end

