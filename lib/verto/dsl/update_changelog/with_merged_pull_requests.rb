module Verto
  module DSL
    class UpdateChangelog
      class WithMergedPullRequests
        include Verto.import[executor: 'system_command_executor_without_output']

        def call(message_pattern = /^[[:space:]]*\[.*\]/)
          executor.run(
            %q(git log --oneline --decorate  | grep -B 100 -m 1 "tag:" | grep "pull request" | awk '{print $1}' | xargs git show --format='%b' | grep -v Approved | grep -v "^$")
          ).output.split("\n").map(&:strip).select { |pr_message| message_pattern.match? pr_message}
        end
      end
    end
  end
end
