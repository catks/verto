RSpec.describe Verto::DSL::Syntax do
   let(:class_with_syntax) { Class.new { include Verto::DSL:: Syntax } }
   let(:instance) { class_with_syntax.new }

  describe '#update_changelog' do
    subject(:update_changelog) { instance.update_changelog(with: source_option, filename: changelog_file) }

    let(:update_changelog_instance) { Verto::DSL::UpdateChangelog.new }
    let(:source_option) { :merged_pull_requests_with_bracketed_labels }
    let(:changelog_file) { 'CHANGELOG.md' }
    let(:user_confirm) { true }
    let(:new_version) { '1.1.1' }

    before do
      allow(instance).to receive(:new_version).and_return(new_version)
      allow(CliHelpers).to receive(:confirm).and_return(user_confirm)
      allow(Verto::DSL::UpdateChangelog).to receive(:new).and_return(update_changelog_instance)
      Verto.current_moment = :before_tag_creation
    end

    it 'calls UpdateChangelog' do
      allow(update_changelog_instance).to receive(:call)

      update_changelog

      expect(update_changelog_instance).to have_received(:call).with(with: source_option,
                                                                     filename: changelog_file,
                                                                     new_version: new_version,
                                                                     confirmation: true)
    end

    context 'when is called without the scope of before_tag_creation or after_tag_up' do
      before { Verto.current_moment = nil }

      it 'raises a error' do
        expect { update_changelog }.to raise_error(Verto::ExitError, "update_changelog is only supported in before_tag_creation or after_command_tag_up")
      end
    end
  end
end
