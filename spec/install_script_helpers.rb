
module InstallScriptHelpers

  def make_scripts_dir
    Dir.mkdir 'scripts'
    Dir.mkdir 'scripts/first-boot'
    Dir.mkdir 'scripts/first-boot/prepend'
    Dir.mkdir 'scripts/first-boot/optional'
    Dir.mkdir 'scripts/first-boot/append'
  end

  def make_install_script(package, subdir = :optional)
    File.open("scripts/first-boot/#{subdir}/install-#{package}.sh", 'w') do |fh|
      fh.write <<-SHELL
#!/bin/sh

apt-get -q -y install #{package}
      SHELL
    end
  end

end
