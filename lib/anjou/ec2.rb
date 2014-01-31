require 'aws-sdk'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'credentials', 'anjou'))

module Anjou
  class EC2
    attr_reader :api

    KEY_ID                = Anjou::AWS::ACCESS_KEY_ID
    SECRET_KEY            = Anjou::AWS::SECRET_ACCESS_KEY
    KEY_PAIR_NAME         = Anjou::AWS::KEY_PAIR_NAME
    USER_VOL_SIZE         = 1 #Gb
    DEFAULT_ZONE          = "us-east-1d"
    DEFAULT_AMI           = 'ami-ad184ac4' # Ubuntu Server 13.10 64bit
    DEFAULT_INSTANCE_TYPE = 't1.micro'
    DEFAULT_USER_DATA     = "#!/bin/sh\n\necho \"Welcome to Anjou!\n\n\" >> /etc/motd\n"
    DEFAULT_SNAPSHOT_NAME = 'anjou-generic'
    SECURITY_GROUP_NAME   = 'Anjou'

    def initialize(access_key_id=KEY_ID, secret_access_key=SECRET_KEY)
      @api = ::AWS::EC2.new(
        access_key_id:     access_key_id,
        secret_access_key: secret_access_key )
    end

    def create_instance(
      username: nil,
      ami: DEFAULT_AMI,
      key_name: KEY_PAIR_NAME,
      zone: DEFAULT_ZONE,
      instance_type: DEFAULT_INSTANCE_TYPE,
      user_data: DEFAULT_USER_DATA
    )
      key_pair = key_pair_for key_name
      raise "Unable to start instance: no such key pair exists! (key_name: #{key_name})" unless key_pair && key_pair.exists?
      @api.instances.create(
        image_id: ami,
        key_pair: key_pair,
        availability_zone: zone,
        instance_type: instance_type,
        user_data: user_data,
        security_groups: security_groups
      ).tap do |instance|
        if username
          instance.tags.Name = name_tag_for username
          instance.tags.owner = username
        end
      end
    end

    def instance_for(username)
      @api.instances.tagged('owner').select do |instance|
        instance.tags.to_a.include? ['owner', username]
      end.select{|i| i.status != :terminated }.last
    end

    def instance_status_for(username)
      instance_for(username).status
    end

    def key_pair_for(key_name)
      @api.key_pairs.select{ |kp| kp.name == key_name }.last
    end

    def create_user_volume(username: nil, user_vol_size: USER_VOL_SIZE, zone: DEFAULT_ZONE, snapshot: DEFAULT_SNAPSHOT_NAME)

      aws_snapshot = @api.snapshots.tagged('Name').select do |snp|
        snp.tags.to_a.include? ['Name', snapshot]
      end.last

      @api.volumes.create(
        size: user_vol_size,
        availability_zone: zone,
        snapshot: aws_snapshot
      ).tap do |volume|
        if username
          volume.tags.Name = name_tag_for username
          volume.tags.owner = username
        end
      end
    end

    def delete_user_volume(username)
      detach(username).delete
    end

    def user_volume_for(username)
      @api.volumes.tagged('owner').select do |vol|
        vol.tags.to_a.include? ['owner', username]
      end.first
    end

    def user_volume_status_for(username)
      user_volume_for(username).status
    end

    #@depricated: this method violates Anjou::EC2's "thin wrapper" contract.
    # It's a useful method, but it should be implemented elsewhere.
    def wait_for_user_volume(username, status: :available, timeout: 15)
      seconds = 0
      while user_volume_status_for(username) != status
        raise "Timeout: After #{timeout} seconds, user volume for #{username} is still not #{status}" if seconds >= timeout
        seconds += sleep 1
      end
      status
    end

    def attach(username, instance, device=nil)
      volume = user_volume_for(username)
      guard_volume_available(volume, username)
      device ||= next_device_for(instance)
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

    def security_groups
      @api.security_groups.to_a.select{ |sg| sg.name == 'Anjou' }
    end

    private

    def name_tag_for(username)
      "anjou-#{username || :generic}"
    end

    def guard_volume_available(volume, username)
      volume.status.tap do |status|
        unless status == :available
          raise "user volume for \"#{username}\" is not available (status: #{status})"
        end
      end
    end
  end
end

