# frozen_string_literal: true

RSpec.describe Verto::DSL do
  describe '.load_file' do
    subject(:load_file) { described_class.load_file(vertofile_path) }

    let(:vertofile) do
      <<~VERTO

        verto_version "#{verto_version}"
        config {
          pre_release.initial_number = 0
          project.path = "#{project_path}"
          changelog.format = <<~CHANGELOG
                               ## {{new_version}} - #{Time.now.strftime('%d/%m/%Y')}
                                {{#version_changes}}
                                * {{.}}
                                {{/version_changes}}
                              CHANGELOG
        }

        before { sh('echo "My Releases" > releases.log') }

        context(branch('master')) {
          config {
            pre_release.initial_number = 1
          }

          sh('echo "On master Branch" > branch')

          before_tag_creation {
            #file('CHANGELOG.md').prepend(\"## \#{new_version} - \#{Time.now.strftime('%d/%m/%Y')}")
            update_changelog
            git!('add CHANGELOG.md')
            git('commit -m "Updates CHANGELOG"')
          }
        }

        context(branch('qa')) {
          config {
            pre_release.initial_number = 2
          }

          sh('echo "On qa Branch" > branch')
          git('status')

          before_command_tag_up {
            command_options.add(pre_release: 'rc')

            has_a_up_version_number = !command_options.keys.any? { |key| [:major, :minor, :patch].include?(key) }

            command_options.add(patch: true) if latest_pre_release_version < latest_release_version && !has_a_up_version_number
          }

          on('before_tag_creation') {
            sh('echo Test!')
          }

          before_command('tag_up') {
            sh('echo "Before Hook" > before_hook')
          }

          after_command('tag_up') {
            sh('echo "After Hook" > after_hook', output: false)

            context(env('DEBUG') == 'true') {
              file('releases.log').append(new_version.to_s)
            }
          }

          after_command_tag_up {
            file('package.json').replace_all(/\\d+\\.\\d+\\.\\d+/, new_version.to_s)
          }
        }

        context(branch(/feature.+/)) {
          config {
            output.stdout_to = "verto.log"
            output.stderr_to = "error.log"
          }

          error "Can't create tags in feature branch"
        }

        context(branch('wip')) {
          file('love').prepend('what_is')
        }

        context(branch('auto_git')) {
          config {
            git.pull_before_tag_creation = true
            git.push_after_tag_creation = true
          }
        }

        after {
          file('verto.log').append(Time.now.strftime('%d-%m-%Y'))
        }
      VERTO
    end

    let(:verto_version) { Verto::VERSION }
    let(:project_path) { Verto.root_path.join('tmp/test_repo') }
    let(:vertofile_path) { project_path.join('Vertofile') }
    let(:package_json_path) { project_path.join('package.json') }
    let(:repo) { TestRepo.new }
    let(:current_branch) { 'master' }
    let(:fake_command) { Class.new(Verto::BaseCommand) }
    let(:command_executor) { Verto::SystemCommandExecutor.new(path: project_path) }

    before do
      repo.reload!
      repo.checkout(current_branch)
      IO.write(vertofile_path, vertofile)
      IO.write(package_json_path, '{ "version": "0.0.0" }')
      Verto.config.hooks = [] # Reset Hooks
      command_executor.run('touch CHANGELOG.md')
      allow(Verto::CliHelpers).to receive(:select_options).and_return(:yes)
      described_class.reset_interpreter!
    end

    around(:each) do |ex|
      ex.run
    rescue SystemExit => e
      puts e
      raise "Command exits in error #{e.message}"
    end

    after do
      repo.clear!
    end

    def run_command(new_version: '1.1.1', before_with_attributes: {}, after_with_attributes: {})
      fake_command.new.instance_eval do
        result = nil

        call_hooks('before')
        call_hooks('before_tag_up', with_attributes: before_with_attributes)
        call_hooks('before_tag_creation', with_attributes: { new_version: new_version })
        result = yield if block_given?
        call_hooks('after_tag_up', with_attributes: after_with_attributes)
        call_hooks('after')

        result
      end
    end

    context 'when a branch doesnt have a specific context' do
      let(:current_branch) { 'without_context' }

      it 'loads the configuration' do
        load_file

        expect(Verto.config.pre_release.initial_number).to eq(0)
      end

      it 'doesnt execute context commands' do
        load_file

        expect(file('branch')).to_not exist
      end
    end

    context 'when branch is master' do
      let(:current_branch) { 'master' }

      it 'loads the context configuration' do
        load_file

        expect(Verto.config.pre_release.initial_number).to eq(1)
      end

      it 'execute the shell command in the context' do
        load_file

        expect(file_content('branch').chomp).to eq('On master Branch')
      end

      it 'run the before_tag_creation hook' do
        load_file

        expect do
          run_command(new_version: '1.2.3', after_with_attributes: { new_version: '1.2.3' }) { true }
        end.to change { file_content('CHANGELOG.md') }.from('').to("## 1.2.3 - #{Time.now.strftime('%d/%m/%Y')}\n\n")

        output = command_executor.run('git log -n 1 HEAD').output
        expect(output).to include('Updates CHANGELOG')
      end
    end

    context 'when branch is qa' do
      let(:current_branch) { 'qa' }

      it 'loads the context configuration' do
        load_file

        expect(Verto.config.pre_release.initial_number).to eq(2)
      end

      it 'execute the shell command in the context' do
        load_file

        expect(file_content('branch').chomp).to eq('On qa Branch')
      end

      it 'adds preconfigured options for tag up' do
        load_file

        on_command_options = run_command(after_with_attributes: { new_version: '1.2.3' }) do
          Verto.config.command_options
        end

        expect(on_command_options).to include(pre_release: 'rc')
      end

      it 'run the before command hook before the command' do
        load_file

        output = run_command(after_with_attributes: { new_version: '1.2.3' }) { file_content('before_hook').chomp }

        expect(output).to eq('Before Hook')
      end

      it 'run the after command hook after the command' do
        load_file

        on_command_output = run_command(after_with_attributes: { new_version: '1.2.3' }) { file('after_hook').exist? }

        expect(on_command_output).to be false

        expect(file_content('after_hook').chomp).to eq('After Hook')
        expect(file_content('package.json').chomp).to eq('{ "version": "1.2.3" }')
      end

      context 'with env DEBUG' do
        before { ENV['DEBUG'] = 'true' }

        it 'run the context in after hook' do
          load_file

          run_command(after_with_attributes: { new_version: '1.2.3-rc.1' }) { true }

          expect(file_content('releases.log')).to eq("My Releases\n1.2.3-rc.1")
        end
      end

      it 'run the after hook after the command' do
        load_file

        run_command(after_with_attributes: { new_version: '1.2.3-rc.1' }) { true }

        expect(file_content('verto.log')).to eq(Time.now.strftime('%d-%m-%Y'))
      end
    end

    context 'when branch is a feature branch' do
      let(:current_branch) { 'feature/my_branch' }

      it 'sets the stderr' do
        load_file

        expect(Verto.config.output.stderr_to).to eq('error.log')
      end

      it 'sets the stdout' do
        load_file

        expect(Verto.config.output.stdout_to).to eq('verto.log')
      end

      it 'saves the error on error.log file' do
        stderr = Verto.container.resolve('stderr')

        allow(stderr).to receive(:puts)

        load_file

        # TODO: Improve test, seeing the file content (Currently only write after proccess finish)
        expect(stderr).to have_received(:puts).with("Can't create tags in feature branch")
      end
    end

    context 'when current branch is a wip brach' do
      let(:current_branch) { 'wip' }

      it 'exits in error when executing the command' do
        expect { load_file }
          .to raise_error(Verto::DSL::Interpreter::Error,
                          %r{No such file or directory @ rb_sysopen - .+verto/tmp/test_repo/love})
      end
    end

    context 'when the verto_version is higher than the current version' do
      let(:verto_version) { Verto::SemanticVersion.new(Verto::VERSION).up(:major) }

      it 'exits in error' do
        expect { load_file }
          .to raise_error(Verto::ExitError,
                          "Current Verto version is #{Verto::VERSION}, required version is #{verto_version} or higher")
      end
    end
  end
end
