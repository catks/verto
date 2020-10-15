# frozen_string_literal: true

RSpec.describe 'verto command' do
  before do
    Verto.config.project.path = project_path.to_s
    $stderr = stderr
    repo.reload!
    allow(Verto::DSL).to receive(:load_file)
    allow(Verto::MainCommand).to receive(:start)
  end

  let(:load_exe) { load exe_path }
  let(:repo) { TestRepo.new }
  let(:stderr) { StringIO.new }
  let(:exe_path) { Verto.root_path.join('exe/verto') }
  let(:project_path) { Verto.root_path.join('tmp/test_repo/') }
  let(:last_tag) { '1.1.1' }
  let(:vertofile_path) { Pathname.new(Dir.pwd).join('Vertofile').to_s }

  context 'when a Vertofile exists' do
    before do
      repo.run("git tag #{last_tag}")
      repo.commit!('Second')
      allow(File).to receive(:exist?).and_return(true)
    end

    it 'loads the Vertofile' do
      load_exe

      expect(Verto::DSL).to have_received(:load_file).with(vertofile_path)
    end

    it 'pass the args to the MainCommand' do
      load_exe

      expect(Verto::MainCommand).to have_received(:start).with(ARGV)
    end
  end

  context 'when a Vertofile doesnt exist' do
    before do
      repo.run("git tag #{last_tag}")
      repo.commit!('Second')
      allow(File).to receive(:exist?).and_return(false)
    end

    it 'doenst load a Vertofile' do
      load_exe

      expect(Verto::DSL).to_not have_received(:load_file)
    end

    it 'pass the args to the MainCommand' do
      load_exe

      expect(Verto::MainCommand).to have_received(:start).with(ARGV)
    end
  end

  context 'with a specific path to Vertofile' do
    before do
      repo.run("git tag #{last_tag}")
      repo.commit!('Second')
      allow(File).to receive(:exist?).and_return(true)
      ENV['VERTOFILE_PATH'] = vertofile_env_path
    end

    after do
      ENV['VERTOFILE_PATH'] = nil
    end

    let(:vertofile_env_path) { 'some/file/path/Vertofile' }

    it 'loads the Vertofile' do
      load_exe

      expect(Verto::DSL).to have_received(:load_file).with(vertofile_env_path)
    end

    it 'pass the args to the MainCommand' do
      load_exe

      expect(Verto::MainCommand).to have_received(:start).with(ARGV)
    end
  end
end
