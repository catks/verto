# frozen_string_literal: true

module Verto
  module DSL
    class UpdateChangelog
      class WithCommitMessages
        include Verto.import[executor: 'system_command_executor_without_output', tag_repository: 'tag_repository']
        include FilteredBy

        def call(message_pattern = /.+/)
          executor.run(
            "git log --no-merges --pretty=format:%s #{commit_range}"
          ).output.split("\n").map(&:strip).select { |message| message_pattern.match? message }
        end

        private

        def commit_range
          return unless latest_tag

          "HEAD ^#{latest_tag}"
        end

        def latest_tag
          tag_repository.latest
        end
      end
    end
  end
end
