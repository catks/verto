# frozen_string_literal: true

RSpec.describe Verto::CliHelpers do
  describe '#edit_text' do
    subject(:edit_text) { described_class.edit_text(text) }

    let(:text) { 'text' }
    let(:random_hex) { '9095d4b9122989c049df3bb61b780c5a' }
    let(:random_filename) { "/tmp/verto-changelog-edit-#{random_hex}" }

    before do
      allow(TTY::Editor).to receive(:open) do |text|
        FileUtils.touch(random_filename)
        text
      end
      allow(SecureRandom).to receive(:hex).and_return(random_hex)
    end

    it 'open the editor' do
      edit_text

      expect(TTY::Editor)
        .to have_received(:open)
        .with(random_filename, text: text)
        .once
    end
  end

  describe '#select_options' do
    subject(:select_options) { described_class.select_options(question, choices) }

    let(:tty_prompt) { instance_double(TTY::Prompt) }
    let(:question) { 'Create new Release?' }
    let(:choices) do
      [
        { key: 'y', name: 'Create a new Release CHANGELOG', value: :yes },
        { key: 'n', name: 'Cancel the Release CHANGELOG', value: :no },
        { key: 'e', name: 'Edit the Release CHANGELOG before continuing', value: :edit }
      ]
    end
    before do
      allow(TTY::Prompt).to receive(:new).and_return(tty_prompt)
      allow(tty_prompt).to receive(:expand).with(question, choices)
    end

    it 'open the options to be select' do
      select_options

      expect(tty_prompt).to have_received(:expand).with(question, choices).once
    end
  end
end
