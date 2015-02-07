module Anjou
  class InstanceUserData
    PREPENDS  = 'scripts/first-boot/prepend'
    OPTIONALS = 'scripts/first-boot/optional'
    APPENDS   = 'scripts/first-boot/append'

    def self.render_mime(*scripts)
      self.new(scripts.flatten).render_mime
    end

    def initialize(scripts=[])
      @scripts = scripts
      @script_sequence = 0
    end

    def render_mime
      generate_mime
      mime_sections.join("\n")
    end

    def to_s
      render_mime
    end

    private

    def generate_mime
      add_to PREPENDS,  [ 'install-ubuntu-updates', 'install-git' ]
      add_to OPTIONALS, @scripts
      add_to APPENDS,   [ 'install-motd' ]
    end

    def add_to(path, scripts)
      scripts.each do |script|
        filename  = "#{script}.sh"
        filepath  = "#{path}/#{filename}"
        mime_sections << file_part(filename, File.read(filepath))
      end
    end

    def boundary
      @boundary ||= "~~Anjou::UserData~~"
    end

    def mime_sections
      @mime_sections ||= [ message_header ]
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

    def file_sequence
      "%03d" % ( @script_sequence += 1 )
    end

    def part_header(filename, content_type: 'text/x-shellscript')
      <<-PART
--#{boundary}
Content-Type: #{content_type}
MIME-Version: 1.0
Content-Disposition: attachment; filename="#{file_sequence}-#{filename}"

      PART
    end

  end
end
