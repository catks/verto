RSpec.describe Verto::DSL do
  describe '.load_file' do
    subject(:load_file) { described_class.load_file(vertofile_path) }

    let(:vertofile) do
      <<~VERTO
        config {
          pre_release.initial_number = 0
          project.path = "#{project_path}"
        }

        before { sh('echo "My Releases" > releases.log') }

        context(branch('master')) {
          config {
            pre_release.initial_number = 1
          }

          sh('echo "On master Branch" > branch')

          on('before_tag_creation') {
            file('CHANGELOG.md').prepend(\"## \#{new_version} - \#{Time.now.strftime('%d/%m/%Y')}")
            git('add CHANGELOG.md')
            git('commit -m "Updates CHANGELOG"')
          }
        }

        context(branch('qa')) {
          config {
            pre_release.initial_number = 2
          }

          sh('echo "On qa Branch" > branch')
          git('status')

          before_command('tag_up') {
            command_options.add(pre_release: 'rc')
            sh('echo "Before Hook" > before_hook')
          }

          after_command('tag_up') {
            sh('echo "After Hook" > after_hook')

            context(env('DEBUG') == 'true') {
              file('releases.log').append(new_version.to_s)
            }

            file('package.json').replace_all(/\\d+\\.\\d+\\.\\d+/, new_version.to_s)
          }
        }

        after {
          file('verto.log').append(Time.now.strftime('%d-%m-%Y'))
        }
      VERTO
    end

    let(:project_path) { Verto.root_path.join('tmp/test_repo') }
    let(:vertofile_path) { project_path.join('Vertofile') }
    let(:package_json_path) { project_path.join('package.json') }
    let(:repo) { TestRepo.new }
    let(:current_branch) { 'master' }
    let(:stderr) { StringIO.new }
    let(:stdout) { StringIO.new }
    let(:fake_command) { Class.new(Verto::BaseCommand) }
    let(:command_executor) { Verto::SystemCommandExecutor.new(path: project_path) }

    before do
      repo.reload!
      repo.checkout(current_branch)
      IO.write(vertofile_path, vertofile)
      IO.write(package_json_path, '{ "version": "0.0.0" }')
      Verto.config.hooks = [] # Reset Hooks
      command_executor.run('touch CHANGELOG.md')
    end

    around(:each) do |ex|
      begin
        ex.run
      rescue SystemExit => e
        puts e
        raise "Command exits in error #{e.message}"
      end
    end

    after do
      repo.clear!
    end

    def run_command(new_version: '1.1.1', before_with_attributes: {}, after_with_attributes: {}, &block)
      fake_command.new.instance_eval do
        result = nil


        call_hooks("before")
        call_hooks("before_tag_up", with_attributes: before_with_attributes)
        call_hooks("before_tag_creation", with_attributes: { new_version: new_version } )
        result = yield if block_given?
        call_hooks("after_tag_up", with_attributes: after_with_attributes)
        call_hooks("after")

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

        expect {
          run_command(new_version: '1.2.3', after_with_attributes: { new_version: '1.2.3' }) { true }
        }.to change { file_content('CHANGELOG.md').chomp }.from('').to("## 1.2.3 - #{Time.now.strftime('%d/%m/%Y')}")

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

        on_command_options = run_command(after_with_attributes: { new_version: '1.2.3' }) { Verto.config.command_options }

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
  end
end
