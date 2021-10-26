# frozen_string_literal: true

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
    subject(:update_changelog) do
      instance.call(with: source_option, filename: changelog_file, new_version: new_version)
    end

    before do
      repo.init!
      allow(Verto::CliHelpers).to receive(:select_options).and_return(user_confirm)
      allow(Verto::CliHelpers).to receive(:edit_text) { |text| text }
      allow(instance).to receive(:new_version).and_return(new_version)
    end

    after do
      repo.clear!
    end

    let(:source_option) { :merged_pull_requests_with_bracketed_labels }
    let(:changelog_file) { 'CHANGELOG.md' }
    let(:user_confirm) { :yes }
    let(:new_version) { '1.1.1' }
    let(:current_time) { Time.now.strftime('%d/%m/%Y') }

    RSpec.shared_examples 'updates CHANGELOG.md' do |expected_changelog_content:|
      it 'asks for confirmation' do
        update_changelog

        expect(Verto::CliHelpers)
          .to have_received(:select_options)
          .with(
            'Create new Release?',
            [
              { key: 'y', name: 'Create a new Release CHANGELOG', value: :yes },
              { key: 'n', name: 'Cancel the Release CHANGELOG', value: :no },
              { key: 'e', name: 'Edit the Release CHANGELOG before continuing', value: :edit }
            ]
          ).once
      end

      context 'when editing the changelog' do
        let(:user_confirm) { :edit }

        it 'edit the changelog' do
          update_changelog

          expect(Verto::CliHelpers)
            .to have_received(:select_options)
            .with(
              'Create new Release?',
              [
                { key: 'y', name: 'Create a new Release CHANGELOG', value: :yes },
                { key: 'n', name: 'Cancel the Release CHANGELOG', value: :no },
                { key: 'e', name: 'Edit the Release CHANGELOG before continuing', value: :edit }
              ]
            ).once

          expect(Verto::CliHelpers)
            .to have_received(:edit_text)
            .with(
              a_kind_of(String)
            ).once
        end
      end

      it 'updates CHANGELOG.md' do
        expect { update_changelog }
          .to change { File.read(repo.path.join(changelog_file)) }
          .to(expected_changelog_content)
      end
    end

    # TODO: Extract merged_pull_requests_with_bracketed_labels tests
    context 'with option merged_pull_requests_with_bracketed_labels' do
      context 'with merged pull requests from bitbucket after last tag' do
        before do
          repo.tag!('1.1.0')
          repo.merge_commit!(
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
          repo.merge_commit!(
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

        context 'with multiple pull requests merged' do
          before do
            repo.merge_commit!(
              <<~COMMIT
                Merge pull request #19 from catks/feature/another_one

                [FEATURE] Another One

              COMMIT
            )
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * [FEATURE] Another One
                                * [FEATURE] Custom Defaults

                             CHANGELOG
        end

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
          expect { update_changelog }
            .to raise_error(Verto::ExitError, "changelog file '#{changelog_file}' doesnt exist")
        end
      end

      context 'with a custom changelog file' do
        let(:changelog_file) { 'changelog.md' }

        before do
          repo.run("touch #{changelog_file}")
          repo.tag!('1.1.0')
          repo.merge_commit!(
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
    end

    context 'with option merged_pull_requests_messages' do
      let(:source_option) { :merged_pull_requests_messages }

      context 'with merged pull requests from bitbucket after last tag' do
        before do
          repo.tag!('1.1.0')
          repo.merge_commit!(
            <<~COMMIT
              Merged in fix/simple_fix (pull request #42)

              A simple fix

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
                            * A simple fix

                         CHANGELOG

        context 'with a changelog with a previous content' do
          before do
            repo.run("echo '## 1.1.0 - 12/10/2020' > #{changelog_file}")
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                           <<~CHANGELOG
                             ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                              * A simple fix

                             ## 1.1.0 - 12/10/2020
                           CHANGELOG
        end
      end

      context 'with merged pull requests from github after last tag' do
        before do
          repo.tag!('1.1.0')
          repo.merge_commit!(
            <<~COMMIT
              Merge pull request #18 from catks/feature/custom_default_identifier

              Custom Defaults

            COMMIT
          )
          repo.run("touch #{changelog_file}")
        end

        include_examples 'updates CHANGELOG.md',
                         expected_changelog_content:
                           <<~CHANGELOG
                             ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                              * Custom Defaults

                           CHANGELOG

        context 'with multiple pull requests merged' do
          before do
            repo.merge_commit!(
              <<~COMMIT
                Merge pull request #19 from catks/feature/another_one

                Another One

              COMMIT
            )
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * Another One
                                * Custom Defaults

                             CHANGELOG
        end

        context 'with a changelog with a previous content' do
          before do
            repo.run("echo '## 1.1.0 - 12/10/2020' > #{changelog_file}")
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * Custom Defaults

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
          expect { update_changelog }
            .to raise_error(Verto::ExitError, "changelog file '#{changelog_file}' doesnt exist")
        end
      end

      context 'with a custom changelog file' do
        let(:changelog_file) { 'changelog.md' }

        before do
          repo.run("touch #{changelog_file}")
          repo.tag!('1.1.0')
          repo.merge_commit!(
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
    end

    context 'with option commits_with_bracketed_labels' do
      let(:source_option) { :commits_with_bracketed_labels }

      context 'with commits and merged pull requests from bitbucket after last tag' do
        before do
          repo.tag!('1.1.0')
          repo.merge_commit!(
            <<~COMMIT
              Merged in fix/simple_fix (pull request #42)

              [FIX] A simple fix

              Approved-by: User One <user1@test.com>
              Approved-by: User Two <user2@test.com>
            COMMIT
          )
          repo.commit!(
            <<~COMMIT
              [TECH] Another commit

              Some description
            COMMIT
          )
          repo.run("touch #{changelog_file}")
        end

        include_examples 'updates CHANGELOG.md',
                         expected_changelog_content:
                         <<~CHANGELOG
                           ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                            * [TECH] Another commit

                         CHANGELOG

        context 'with a changelog with a previous content' do
          before do
            repo.run("echo '## 1.1.0 - 12/10/2020' > #{changelog_file}")
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                           <<~CHANGELOG
                             ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                              * [TECH] Another commit

                             ## 1.1.0 - 12/10/2020
                           CHANGELOG
        end
      end

      context 'with commits and merged pull requests from github after last tag' do
        before do
          repo.tag!('1.1.0')
          repo.merge_commit!(
            <<~COMMIT
              Merge pull request #18 from catks/feature/custom_default_identifier

              [FEATURE] Custom Defaults

            COMMIT
          )
          repo.commit!(
            <<~COMMIT
              [TECH] Another commit

              Some description
            COMMIT
          )
          repo.run("touch #{changelog_file}")
        end

        include_examples 'updates CHANGELOG.md',
                         expected_changelog_content:
                           <<~CHANGELOG
                             ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                              * [TECH] Another commit

                           CHANGELOG

        context 'with multiple new commits' do
          before do
            repo.commit!(
              <<~COMMIT
                [FEATURE] Another One

              COMMIT
            )
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * [FEATURE] Another One
                                * [TECH] Another commit

                             CHANGELOG
        end

        context 'with a changelog with a previous content' do
          before do
            repo.run("echo '## 1.1.0 - 12/10/2020' > #{changelog_file}")
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * [TECH] Another commit

                               ## 1.1.0 - 12/10/2020
                             CHANGELOG
        end
      end

      context 'with a couple of commits with bracketed labels' do
        before do
          repo.tag!('1.1.0')
          repo.commit!(
            <<~COMMIT
              [FEATURE] My Feature
            COMMIT
          )
          repo.commit!(
            <<~COMMIT
              [TECH] Another Thing

              Some description here
            COMMIT
          )
          repo.run("touch #{changelog_file}")
        end

        include_examples 'updates CHANGELOG.md',
                         expected_changelog_content:
                           <<~CHANGELOG
                             ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                              * [TECH] Another Thing
                              * [FEATURE] My Feature

                           CHANGELOG

        context 'with multiple commits and pull requests merged' do
          before do
            repo.merge_commit!(
              <<~COMMIT
                Merge pull request #19 from catks/feature/another_one

                [FEATURE] Another One

              COMMIT
            )
            repo.commit!(
              <<~COMMIT
                [TECH] Another Thing 2

                Some description here 2
              COMMIT
            )
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * [TECH] Another Thing 2
                                * [TECH] Another Thing
                                * [FEATURE] My Feature

                             CHANGELOG
        end

        context 'with a changelog with a previous content' do
          before do
            repo.run("echo '## 1.1.0 - 12/10/2020' > #{changelog_file}")
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * [TECH] Another Thing
                                * [FEATURE] My Feature

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
          expect { update_changelog }
            .to raise_error(Verto::ExitError, "changelog file '#{changelog_file}' doesnt exist")
        end
      end

      context 'with a custom changelog file' do
        let(:changelog_file) { 'changelog.md' }

        before do
          repo.run("touch #{changelog_file}")
          repo.tag!('1.1.0')
          repo.commit!(
            <<~COMMIT
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
    end

    context 'with option commit_messages' do
      let(:source_option) { :commit_messages }

      context 'with commits and merged pull requests from bitbucket after last tag' do
        before do
          repo.tag!('1.1.0')
          repo.merge_commit!(
            <<~COMMIT
              Merged in fix/simple_fix (pull request #42)

              [FIX] A simple fix

              Approved-by: User One <user1@test.com>
              Approved-by: User Two <user2@test.com>
            COMMIT
          )
          repo.commit!(
            <<~COMMIT
              [TECH] Another commit

              Some description
            COMMIT
          )

          repo.commit!(
            <<~COMMIT
              Commit without Bracketed labels

              Some description
            COMMIT
          )
          repo.run("touch #{changelog_file}")
        end

        include_examples 'updates CHANGELOG.md',
                         expected_changelog_content:
                         <<~CHANGELOG
                           ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                            * Commit without Bracketed labels
                            * [TECH] Another commit
                            * Test Commit

                         CHANGELOG

        context 'with a changelog with a previous content' do
          before do
            repo.run("echo '## 1.1.0 - 12/10/2020' > #{changelog_file}")
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                           <<~CHANGELOG
                             ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                              * Commit without Bracketed labels
                              * [TECH] Another commit
                              * Test Commit

                             ## 1.1.0 - 12/10/2020
                           CHANGELOG
        end
      end

      context 'with commits and merged pull requests from github after last tag' do
        before do
          repo.tag!('1.1.0')
          repo.merge_commit!(
            <<~COMMIT
              Merge pull request #18 from catks/feature/custom_default_identifier

              [FEATURE] Custom Defaults

            COMMIT
          )
          repo.commit!(
            <<~COMMIT
              [TECH] Another commit

              Some description
            COMMIT
          )

          repo.commit!(
            <<~COMMIT
              Commit without Bracketed labels

              Some description
            COMMIT
          )
          repo.run("touch #{changelog_file}")
        end

        include_examples 'updates CHANGELOG.md',
                         expected_changelog_content:
                           <<~CHANGELOG
                             ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                              * Commit without Bracketed labels
                              * [TECH] Another commit
                              * Test Commit

                           CHANGELOG

        context 'with multiple new commits' do
          before do
            repo.commit!(
              <<~COMMIT
                Another One

              COMMIT
            )
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * Another One
                                * Commit without Bracketed labels
                                * [TECH] Another commit
                                * Test Commit

                             CHANGELOG
        end

        context 'with a changelog with a previous content' do
          before do
            repo.run("echo '## 1.1.0 - 12/10/2020' > #{changelog_file}")
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * Commit without Bracketed labels
                                * [TECH] Another commit
                                * Test Commit

                               ## 1.1.0 - 12/10/2020
                             CHANGELOG
        end
      end

      context 'with a couple of commits' do
        before do
          repo.tag!('1.1.0')
          repo.commit!(
            <<~COMMIT
              My Feature
            COMMIT
          )
          repo.commit!(
            <<~COMMIT
              [TECH] Another Thing

              Some description here
            COMMIT
          )
          repo.run("touch #{changelog_file}")
        end

        include_examples 'updates CHANGELOG.md',
                         expected_changelog_content:
                           <<~CHANGELOG
                             ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                              * [TECH] Another Thing
                              * My Feature

                           CHANGELOG

        context 'with multiple commits and pull requests merged' do
          before do
            repo.merge_commit!(
              <<~COMMIT
                Merge pull request #19 from catks/feature/another_one

                [FEATURE] Another One

              COMMIT
            )
            repo.commit!(
              <<~COMMIT
                Another Thing 2

                Some description here 2
              COMMIT
            )
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * Another Thing 2
                                * [TECH] Another Thing
                                * Test Commit
                                * My Feature

                             CHANGELOG
        end

        context 'with a changelog with a previous content' do
          before do
            repo.run("echo '## 1.1.0 - 12/10/2020' > #{changelog_file}")
          end

          include_examples 'updates CHANGELOG.md',
                           expected_changelog_content:
                             <<~CHANGELOG
                               ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                                * [TECH] Another Thing
                                * My Feature

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
                              * First

                           CHANGELOG
      end

      context 'without a changelog file' do
        it 'raises a error' do
          expect { update_changelog }
            .to raise_error(Verto::ExitError, "changelog file '#{changelog_file}' doesnt exist")
        end
      end

      context 'with a custom changelog file' do
        let(:changelog_file) { 'changelog.md' }

        before do
          repo.run("touch #{changelog_file}")
          repo.tag!('1.1.0')
          repo.commit!(
            <<~COMMIT
              Custom Defaults

            COMMIT
          )
        end

        include_examples 'updates CHANGELOG.md',
                         expected_changelog_content:
                           <<~CHANGELOG
                             ## 1.1.1 - #{Time.now.strftime('%d/%m/%Y')}
                              * Custom Defaults

                           CHANGELOG
      end
    end

    context 'with a invalid source option' do
      let(:source_option) { :not_a_option }

      before do
        repo.run("touch #{changelog_file}")
      end

      it 'raises a error' do
        expect { update_changelog }
          .to raise_error(Verto::DSL::UpdateChangelog::InvalidChangelogSource,
                          'Invalid CHANGELOG Source, avaliable options: ' \
                          "'merged_pull_requests_with_bracketed_labels,commits_with_bracketed_labels," \
                          "merged_pull_requests_messages,commit_messages'")
      end
    end
  end
end
