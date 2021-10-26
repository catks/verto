# frozen_string_literal: true

module Verto
  module DSL
    class UpdateChangelog
      class WithMergedPullRequests
        include Verto.import[executor: 'system_command_executor_without_output']
        include FilteredBy

        def call(message_pattern = /.+/)
          # FIXME: Format the command
          executor.run(
            %q(git log --oneline --decorate  | grep -B 100 -m 1 "tag:" | grep "pull request" | awk '{print $1}' | xargs -r git show --format='%b' | grep -v Approved | grep -v "^$") # rubocop:disable Layout/LineLength
          ).output.split("\n").map(&:strip).select { |pr_message| message_pattern.match? pr_message }
        end
      end
    end
  end
end
