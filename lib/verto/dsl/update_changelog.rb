# frozen_string_literal: true

module Verto
  module DSL
    class UpdateChangelog
      include Verto.import[:cli_helpers, :stdout, changelog_format: 'changelog.format']

      InvalidChangelogSource = Class.new(Verto::ExitError)

      BRACKETED_LABELS_REGEXP = /^[[:space:]]*\[.*\]/.freeze

      SOURCES = StrictHash.new(
        {
          merged_pull_requests_with_bracketed_labels: WithMergedPullRequests.filtered_by(BRACKETED_LABELS_REGEXP),
          commits_with_bracketed_labels: WithCommitMessages.filtered_by(BRACKETED_LABELS_REGEXP),
          merged_pull_requests_messages: WithMergedPullRequests,
          commit_messages: WithCommitMessages
        },
        default_proc: ->(hash, _) { raise InvalidChangelogSource, "Invalid CHANGELOG Source, avaliable options: '#{hash.keys.join(',')}'" }
      )

      def call(new_version:, confirmation: true, filename: 'CHANGELOG.md', with: :merged_pull_requests_with_bracketed_labels, message_pattern: nil)
        verify_file_presence!(filename)

        changelog_changes = format_changes(new_version, version_changes(with, message_pattern))

        if confirmation
          stdout.puts separator
          stdout.puts changelog_changes
          stdout.puts separator
          changelog_changes = select_changelog_text(changelog_changes)
        end

        update_file(filename, changelog_changes)
      end

      private

      # TODO: Refactor
      def select_changelog_text(changelog_changes) # rubocop:disable Metrics/MethodLength
        choices = [
          { key: 'y', name: 'Create a new Release CHANGELOG', value: :yes },
          { key: 'n', name: 'Cancel the Release CHANGELOG', value: :no },
          { key: 'e', name: 'Edit the Release CHANGELOG before continuing', value: :edit }
        ]
        case cli_helpers.select_options('Create new Release?', choices)
        when :no
          exit
        when :edit
          cli_helpers.edit_text(changelog_changes)
        else
          changelog_changes
        end
      end

      def verify_file_presence!(filename)
        return if Verto.project_path.join(filename).exist?

        raise Verto::ExitError, "changelog file '#{filename}' doesnt exist"
      end

      def version_changes(with, message_pattern)
        SOURCES[with.to_sym].new.call(*args_if_any(message_pattern))
      end

      def update_file(filename, changelog_changes)
        DSL::File.new(filename).prepend(changelog_changes)
      end

      def format_changes(new_version, version_changes)
        changes = Mustache.render(changelog_format,
                                  { new_version: new_version, version_changes: version_changes })
        "#{changes}\n"
      end

      def separator
        '---------------------------'
      end

      def args_if_any(arg)
        [arg].compact
      end
    end
  end
end
