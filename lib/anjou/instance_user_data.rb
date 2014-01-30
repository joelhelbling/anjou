module Anjou
  class InstanceUserData

    def initialize(scripts=[])
      @scripts = scripts
    end

    def render_mime
      mime_sections = [ message_header ]
      @scripts.each do |script|
        filename  = "#{script}.sh"
        filepath  = "scripts/first-boot/#{filename}"
        mime_sections << file_part(filename, File.read(filepath))
      end

      mime_sections.join("\n")
    end

    def to_s
      render_mime
    end

    private

    def boundary
      @boundary ||= "~~Anjou::UserData~~"
    end

    def message_header
      <<-HEADER
Content-Type: multipart/mixed; boundary=#{boundary}
MIME-Version: 1.0

      HEADER
    end

    def file_part(filename, file_contents)
      [ part_header(filename), file_contents ].join
    end

    def part_header(filename, content_type: 'text/x-shellscript')
      <<-PART
--#{boundary}
Content-Type: #{content_type}
MIME-Version: 1.0
Content-Disposition: attachment; filename="#{filename}"

      PART
    end

  end
end
