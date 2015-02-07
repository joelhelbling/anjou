require 'anjou/instance_user_data'

module Anjou
  describe InstanceUserData do
    it { should respond_to :render_mime }

    describe "#render_mime", :fakefs do
      before do
        make_scripts_dir
        make_install_script 'ubuntu-updates', :prepend
        make_install_script 'git', :prepend
        make_install_script 'foo'
        make_install_script 'bar'
        make_install_script 'baz'
        make_install_script 'motd', :append
      end

      context "for a subset of existing scripts" do
        subject { described_class.new ["install-foo", "install-bar"] }
        its(:render_mime) { should include("apt-get -q -y install foo") }
        its(:render_mime) { should include("install bar") }
        its(:render_mime) { should_not include("install baz") }
      end

      context "for a non-existant script" do
        subject { described_class.new ["install-bop"] }
        it "throws an error" do
          expect{ subject.render_mime }.to raise_error
        end
      end

    end

  end # describe InstanceUserData
end
