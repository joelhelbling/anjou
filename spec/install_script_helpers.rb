
module InstallScriptHelpers

  def make_scripts_dir
    Dir.mkdir 'scripts'
    Dir.mkdir 'scripts/first-boot'
  end

  def make_install_script(package)
    File.open("scripts/first-boot/install-#{package}.sh", 'w') do |fh|
      fh.write <<-SHELL
#!/bin/sh

apt-get -q -y install #{package}
      SHELL
    end
  end

end
