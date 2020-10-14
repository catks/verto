RSpec.describe Verto::DSL::UpdateChangelog do
  before do
    Verto.config.project.path = repo.path.to_s
    allow(Verto).to receive(:stdout).and_return(stdout)
    allow(Verto).to receive(:stderr).and_return(stderr)
  end

  let(:repo) { TestRepo.new }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:instance) { described_class.new }

  describe '#call' do
    subject(:update_changelog) { instance.call(with: source_option, filename: changelog_file, new_version: new_version) }

    before do
      repo.init!
      allow(CliHelpers).to receive(:confirm).and_return(user_confirm)
      allow(instance).to receive(:new_version).and_return(new_version)
    end

    after do
      repo.clear!
    end

    let(:source_option) { :merged_pull_requests_with_bracketed_labels }
    let(:changelog_file) { 'CHANGELOG.md' }
    let(:user_confirm) { true }
    let(:new_version) { '1.1.1' }
    let(:current_time) { Time.now.strftime('%d/%m/%Y') }

    RSpec.shared_examples 'updates CHANGELOG.md' do |expected_changelog_content:|
      it 'asks for confirmation' do
        update_changelog

        expect(CliHelpers).to have_received(:confirm).once
      end

      it 'updates CHANGELOG.md' do
        expect { update_changelog }
          .to change { File.read(repo.path.join(changelog_file)) }
          .to(expected_changelog_content)
      end
    end

    context 'with merged pull requests from bitbucket after last tag' do
      before do
        repo.tag!('1.1.0')
        repo.commit!(
          <<~COMMIT
          Merged in fix/simple_fix (pull request #42)

          [FIX] A simple fix

          Approved-by: User One <user1@test.com>
          Approved-by: User Two <user2@test.com>
          COMMIT
        )
        repo.run("touch #{changelog_file}")
      end

      include_examples 'updates CHANGELOG.md',
        expected_changelog_content:
        <<~CHANGELOG
                          ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                           * [FIX] A simple fix

      CHANGELOG

      context 'with a changelog with a previous content' do
        before do
          repo.run("echo '## 1.1.0 - 12/10/2020' > #{changelog_file}")
        end

        include_examples 'updates CHANGELOG.md',
          expected_changelog_content:
          <<~CHANGELOG
                            ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                             * [FIX] A simple fix

                            ## 1.1.0 - 12/10/2020
        CHANGELOG
      end
    end

    context 'with merged pull requests from github after last tag' do
      before do
        repo.tag!('1.1.0')
        repo.commit!(
          <<~COMMIT
            Merge pull request #18 from catks/feature/custom_default_identifier

            [FEATURE] Custom Defaults

          COMMIT
        )
        repo.run("touch #{changelog_file}")
      end

      include_examples 'updates CHANGELOG.md',
        expected_changelog_content:
        <<~CHANGELOG
                          ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                           * [FEATURE] Custom Defaults

      CHANGELOG

      context 'with a changelog with a previous content' do
        before do
          repo.run("echo '## 1.1.0 - 12/10/2020' > #{changelog_file}")
        end

        include_examples 'updates CHANGELOG.md',
          expected_changelog_content:
          <<~CHANGELOG
                            ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                             * [FEATURE] Custom Defaults

                            ## 1.1.0 - 12/10/2020
        CHANGELOG
      end
    end

    context 'without merged pull requests' do
      before do
        repo.run("touch #{changelog_file}")
      end

      include_examples 'updates CHANGELOG.md',
        expected_changelog_content:
        <<~CHANGELOG
                            ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}

      CHANGELOG
    end

    context 'without a changelog file' do
      it 'raises a error' do
        expect { update_changelog }.to raise_error(Verto::ExitError, "changelog file '#{changelog_file}' doesnt exist")
      end
    end

    context 'with a custom changelog file' do
      let(:changelog_file) { 'changelog.md' }

      before do
        repo.run("touch #{changelog_file}")
        repo.tag!('1.1.0')
        repo.commit!(
          <<~COMMIT
            Merge pull request #18 from catks/feature/custom_default_identifier

            [FEATURE] Custom Defaults

          COMMIT
        )
      end

      include_examples 'updates CHANGELOG.md',
        expected_changelog_content:
        <<~CHANGELOG
                          ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                           * [FEATURE] Custom Defaults

      CHANGELOG
    end

    context 'with a invalid source option' do
      let(:source_option) { :not_a_option }

      before do
        repo.run("touch #{changelog_file}")
      end

      it 'raises a error' do
        expect { update_changelog }
          .to raise_error(Verto::DSL::UpdateChangelog::InvalidChangelogSource,
                          "Invalid CHANGELOG Source, avaliable options: 'merged_pull_requests_with_bracketed_labels'")
      end
    end
  end
end
