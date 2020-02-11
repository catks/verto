RSpec.describe Verto::DSL do
  describe '.load_file' do
    subject(:load_file) { described_class.load_file(vertofile_path) }

    let(:vertofile) do
      <<~VERTO
        config {
          pre_release.initial_number = 0
          project.path = "#{Verto.root_path.join('tmp/test_repo/')}"
        }

        context(branch('master')) {
          config {
            pre_release.initial_number = 1
          }

          sh('echo "On master Branch" > branch')
          git('status')
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
          }
        }
      VERTO
    end

    let(:vertofile_path) { '/some/file/path' }
    let(:repo) { TestRepo.new }
    let(:current_branch) { 'master' }
    let(:stderr) { StringIO.new }
    let(:stdout) { StringIO.new }
    let(:fake_command) { Class.new(Verto::BaseCommand) }

    before do
      allow(IO).to receive(:read).with(vertofile_path).and_return(vertofile)
      repo.reload!
      repo.checkout(current_branch)
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

    def run(command_name)
      fake_command.new.instance_eval do
        result = nil

        call_before_hooks(command_name)
        result = yield if block_given?
        call_after_hooks(command_name)

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

        expect(file_content('branch')).to eq('On master Branch')
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

        expect(file_content('branch')).to eq('On qa Branch')
      end

      it 'adds preconfigured options for tag up' do
        load_file

        on_command_options = run('tag_up') { Verto.config.command_options }

        expect(on_command_options).to include(pre_release: 'rc')
      end

      it 'run the before hook before the command' do
        load_file

        output = run('tag_up') { file_content('before_hook') }

        expect(output).to eq('Before Hook')
      end

      it 'run the after hook after the command' do
        load_file

        on_command_output = run('tag_up') { file('after_hook').exist? }

        expect(on_command_output).to be false

        expect(file_content('after_hook')).to eq('After Hook')
      end
    end
  end
end
