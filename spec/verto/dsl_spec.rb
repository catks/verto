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
        }
      VERTO
    end

    let(:vertofile_path) { '/some/file/path' }
    let(:repo) { TestRepo.new }
    let(:current_branch) { 'master' }
    let(:stderr) { StringIO.new }
    let(:stdout) { StringIO.new }
    let(:sh_output_file) { Verto.root_path.join(Verto.config.project.path, 'branch') }
    let(:sh_output) do
      sh_output_file.readlines.first.chomp
    end

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

    context 'when a branch doesnt have a specific context' do
      let(:current_branch) { 'without_context' }

      it 'loads the configuration' do
        load_file

        expect(Verto.config.pre_release.initial_number).to eq(0)
      end

      it 'doesnt execute context commands' do
        load_file

        expect(sh_output_file).to_not exist
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

        expect(sh_output).to eq('On master Branch')
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

        expect(sh_output).to eq('On qa Branch')
      end
    end
  end
end
