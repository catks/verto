# frozen_string_literal: true

module Verto
  module DSL
    module BuiltInHooks
      GitPullCurrentBranch = DSL::Hook.new(moment: :before) do
        git!("pull origin #{current_branch}")
      end

      GitFetch = DSL::Hook.new(moment: :before) do
        git!('fetch')
      end

      GitPushTags = DSL::Hook.new(moment: :after) do
        git!('push --tags')
      end

      GitPushCurrentBranchCommits = DSL::Hook.new(moment: :after) do
        git!("push origin #{current_branch}")
      end

      GitPushCurrentBranch = DSL::Hook.new(moment: :after) do
        GitPushTags.call
        GitPushCurrentBranchCommits.call
      end
    end
  end
end
