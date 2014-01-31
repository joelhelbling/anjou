module Anjou
  class UserHome
    ANJOU_LOGIN = 'ubuntu'
    SSH_READY_TIMEOUT = 30

    def initialize(username, hostname)
      @username = username
      @hostname = hostname
    end

    def create_linux_user
      ssh_do "sudo adduser --disabled-password --gecos '#{@username}' #{@username}"
      # ssh_do "sudo adduser #{@username} sudo"
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
      until ! `#{ssh_cmd} ls 2>&1`.match(/Connection refused/) do
        raise "ssh connection refused! (retried #{timeout} times)" if timeout >= SSH_READY_TIMEOUT
        puts " - connection refused, waiting a second..."
        sleep 1
        timeout += 1
      end
    end

    def ssh_cmd
      @ssh_cmd ||= "ssh -o 'StrictHostKeyChecking no' #{ANJOU_LOGIN}@#{@hostname}"
    end

  end
end
