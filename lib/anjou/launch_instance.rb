require 'anjou'

module Anjou
  class LaunchInstance
    LAUNCH_TIMEOUT_SECONDS = 60 * 5

    class << self

      def create_and_launch_instance(users=[], host_user: nil)
        host_user ||= users.first
        users << host_user unless users.include? host_user

        guard_enough users

        ensure_volumes_for users

        user_data = Anjou::InstanceUserData.render_mime 'install-ruby', 'install-mosh'

        create_instance_for(host_user, user_data).tap do |instance|
          attach users, instance

          users.each do |user|
            home = Anjou::UserHome.new user, instance.dns_name
            puts "Creating login for #{user}..."
            home.create_linux_user
            puts "Mounting home directory for #{user}..."
            home.mount_home_dir
          end
        end

      end

      private

      def ec2
        @@ec2 ||= Anjou::EC2.new
      end

      def guard_enough users
        raise "You must provide at least one user for this pairing workstation!" unless users.size > 0
      end

      def create_instance_for host_user, user_data
        puts "Creating Anjou instance for host user #{host_user}..."
        instance = ec2.create_instance username: host_user, user_data: user_data

        timeout_seconds = LAUNCH_TIMEOUT_SECONDS
        until instance.status == :running do
          raise "instance failed to start after #{LAUNCH_TIMEOUT_SECONDS}" if timeout_seconds <= 0
          sleep 1; timeout_seconds -= 1
        end
        puts "Anjou instance started at #{instance.dns_name} :)"
        instance
      end

      def ensure_volumes_for users
        users.each do |user|
          unless ec2.user_volume_for(user)
            puts "Creating user volume for #{user}"
            ec2.create_user_volume(username: user)
          end
        end
      end

      def attach users, instance
        users.each do |user|
          puts "Attaching user volume for #{user} to #{instance.dns_name}"
          ec2.attach user, instance
        end
      end
    end
  end
end
