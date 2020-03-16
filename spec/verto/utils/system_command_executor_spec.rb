require 'stringio'

RSpec.describe Verto::SystemCommandExecutor do
  let(:instance) { described_class.new(path: './') }

  describe  '#run' do
    subject(:run) { instance.run(command) }

    context 'with a command that exit with success' do
      let(:command) { 'echo "Opa"' }

      it 'returns the command result' do
        is_expected.to have_attributes(
          output: "Opa\n",
          error: '',
          result: instance_of(Process::Status)
        )
      end

      it 'executes the command successfully' do
        is_expected.to be_a_success

        is_expected.to_not be_a_error
      end
    end

    context 'with a command that exit with error' do
      let(:command) { 'exit 123' }

      it 'returns the command result' do
        is_expected.to have_attributes(
          output: '',
          error: '',
          result: instance_of(Process::Status)
        )
      end

      it 'executes the command with error' do
        is_expected.to_not be_a_success

        is_expected.to be_a_error
      end
    end

    context 'with stdout and stderr' do
      let(:command) { 'echo "Opa"' }

      it 'log the running command on stderr' do
        allow(Verto.stderr).to receive(:puts)

        run

        expect(Verto.stderr).to have_received(:puts).with("Running: #{command}")
      end

      context 'with custom path' do
        let(:instance) { described_class.new(path: './tmp') }

        it 'log the running command on stderr' do
          allow(Verto.stderr).to receive(:puts)

          run

          expect(Verto.stderr).to have_received(:puts).with("Running: #{command} (in ./tmp)")
        end
      end
    end
  end
end

