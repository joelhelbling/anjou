require 'net/sftp'

module Anjou
  class UserHome
    ANJOU_LOGIN = 'ubuntu'
    SSH_READY_TIMEOUT = 300
    SSH_READY_SLEEP_INCREMENT = 2

    def initialize(username, hostname)
      @username = username
      @hostname = hostname
    end

    def create_linux_user
      ssh_do "sudo adduser --disabled-password --gecos '#{@username}' #{@username}"
      ssh_do "echo '#{@username} ALL=(ALL) NOPASSWD:ALL' > /tmp/sudoize-#{@username}"
      ssh_do "sudo chown root:root /tmp/sudoize-#{@username}"
      ssh_do "sudo chmod 440 /tmp/sudoize-#{@username}"
      ssh_do "sudo mv /tmp/sudoize-#{@username} /etc/sudoers.d/"
    end

    def mount_home_dir
      volume = api.user_volume_for @username
      device = volume.attachments.to_a.first.device.gsub(/sda/, "xvda")
      ssh_do "sudo mount #{device} /home/#{@username}"
    end

    def install_authorized_keys(authorized_keys=Anjou::AuthorizedKeys.new(@username))
      if ssh_do("sudo ls /home/#@username/.ssh").include? 'authorized_keys'
        puts "  ...on second thought, skipping this since #@username already has one..."
      else
        Net::SSH.start(@hostname, ANJOU_LOGIN) do |ssh|
          ssh.sftp.connect do |sftp|
            sftp.file.open("#{@username}-authorized_keys", 'w') do |fh|
              fh.write authorized_keys.contents
            end
          end
        end
        ssh_do "sudo mv ~#{ANJOU_LOGIN}/#@username-authorized_keys ~#@username/.ssh/authorized_keys"
        ssh_do "sudo chmod 0600 ~#@username/.ssh/authorized_keys"
      end
      ssh_do "sudo chown -R #@username:#@username /home/#@username"
    end

    private

    def api
      @api ||= Anjou::EC2.new
    end

    def ssh_do(cmd)
      ensure_ssh_ready
      `#{ssh_cmd} "#{cmd}"`
    end

    def ensure_ssh_ready
      timeout = 0
      until ssh_ready? do
        raise "SSH connection not ready after #{timeout} attempts." if timeout >= (SSH_READY_TIMEOUT / SSH_READY_SLEEP_INCREMENT)
        puts " ...connection not ready, waiting a bit..."
        sleep SSH_READY_SLEEP_INCREMENT
        timeout += 1
      end
    end

    def ssh_ready?
      @ssh_ready ||= `#{ssh_cmd} ls /var/lib/cloud/instance/* 2>&1`.include? 'boot-finished'
    end

    def ssh_cmd
      @ssh_cmd ||= "ssh -o 'StrictHostKeyChecking no' #{ANJOU_LOGIN}@#{@hostname}"
    end

  end
end
