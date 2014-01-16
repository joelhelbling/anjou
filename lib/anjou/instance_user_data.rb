require 'mime'

module Anjou
  class InstanceUserData
    include MIME

    def initialize(scripts=[])
      @scripts = scripts
    end

    def render_mime
      install_script = MIME::MultipartMedia::Mixed.new

      @scripts.each do |script|
        filename  = "#{script}.sh"
        filepath  = "scripts/#{filename}"
        mime_part = TextMedia.new File.read(filepath), 'text/x-shellscript'

        install_script.attach_entity mime_part, filename: filename
      end

      install_script.to_s
    end

  end
end
