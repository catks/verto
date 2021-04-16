# frozen_string_literal: true

RSpec.describe Verto::DSL::BuiltInHooks do
  let(:interpreter) { Verto::DSL.interpreter }
  let(:repo) { TestRepo.new }
  let(:current_branch) { 'master' }

  before do
    Verto.config.project.path = Verto.root_path.join('tmp/test_repo/').to_s
    repo.clear!
    repo.init!
  end

  describe described_class::GitPullCurrentBranch do
    subject(:call) { described_class.call }

    it 'pull current branch changes' do
      allow(interpreter).to receive(:git!)

      call

      expect(interpreter).to have_received(:git!).with("pull origin #{current_branch}").once
    end
  end

  describe described_class::GitFetch do
    subject(:call) { described_class.call }

    it 'pull current branch changes' do
      allow(interpreter).to receive(:git!)

      call

      expect(interpreter).to have_received(:git!).with('fetch').once
    end
  end

  describe described_class::GitPushTags do
    subject(:call) { described_class.call }

    it 'pull current branch changes' do
      allow(interpreter).to receive(:git!)

      call

      expect(interpreter).to have_received(:git!).with('push --tags').once
    end
  end

  describe described_class::GitPushCurrentBranchCommits do
    subject(:call) { described_class.call }

    it 'pull current branch changes' do
      allow(interpreter).to receive(:git!)

      call

      expect(interpreter).to have_received(:git!).with("push origin #{current_branch}").once
    end
  end

  describe described_class::GitPushCurrentBranch do
    subject(:call) { described_class.call }

    it 'pull current branch changes' do
      allow(interpreter).to receive(:git!)

      call

      expect(interpreter).to have_received(:git!).with('push --tags').once
      expect(interpreter).to have_received(:git!).with("push origin #{current_branch}").once
    end
  end
end
