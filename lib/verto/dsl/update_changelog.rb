# frozen_string_literal: true

module Verto
  module DSL
    class UpdateChangelog
      include Verto.import[:cli_helpers, :stdout,
                           executor: 'system_command_executor_without_output', changelog_format: 'changelog.format']

      InvalidChangelogSource = Class.new(Verto::ExitError)

      SOURCES = StrictHash.new(
        {
          merged_pull_requests_with_bracketed_labels: lambda do |executor|
            executor.run(
              %q(git log --oneline --decorate  | grep -B 100 -m 1 "tag:" | grep "pull request" | awk '{print $1}' | xargs git show --format='%b' | grep -v Approved | grep -v "^$" | grep -E "^[[:space:]]*\[.*\]")
            ).output.split('\n').map(&:strip)
          end
        },
        default_proc: ->(hash, _) { raise InvalidChangelogSource, "Invalid CHANGELOG Source, avaliable options: '#{hash.keys.join(',')}'" }
      )

      def call(new_version:, confirmation: true, filename: 'CHANGELOG.md', with: :merged_pull_requests_with_bracketed_labels)
        verify_file_presence!(filename)

        stdout.puts separator
        changelog_changes = format_changes(new_version, version_changes(with))

        exit if confirmation && !cli_helpers.confirm("Create new Realease?\n" \
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

      def version_changes(with)
        SOURCES[with].call(executor)
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
    end
  end
end
