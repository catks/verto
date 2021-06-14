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

        stdout.puts separator
        changelog_changes = format_changes(new_version, version_changes(with, message_pattern))

        exit if confirmation && !cli_helpers.confirm("Create new Release?\n" \
                                                     "#{separator}\n" \
                                                     "#{changelog_changes}" \
                                                     "#{separator}\n")
        update_file(filename, changelog_changes)
      end

      private

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
        Mustache.render(changelog_format, { new_version: new_version, version_changes: version_changes }) + "\n"
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
