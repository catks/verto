# frozen_string_literal: true

module Verto
  module DSL
    module Syntax
      def verto_version(expected_version_string)
        expected_version = Verto::SemanticVersion.new(expected_version_string)

        verto_version = Verto::SemanticVersion.new(Verto::VERSION)

        error_message = "Current Verto version is #{verto_version}, required version is #{expected_version} or higher"
        raise Verto::ExitError, error_message unless expected_version <= verto_version
      end

      def config(&block)
        Verto.config.instance_eval(&block)
      end

      def latest_version
        @latest_version ||= latest_semantic_version_for(:all)
      end

      def latest_release_version
        @latest_release_version ||= latest_semantic_version_for(:release_only)
      end

      def latest_pre_release_version
        @latest_pre_release_version ||= latest_semantic_version_for(:pre_release_only)
      end

      def current_branch
        @current_branch ||= git('rev-parse --abbrev-ref HEAD', output: false).output.chomp.strip
      end

      def branch(*branch_names)
        branch_names.any? do |branch|
          return branch.match?(current_branch) if branch.is_a?(Regexp)

          branch.to_s.include? current_branch
        end
      end

      def context(condition, &block)
        block.call if condition
      end

      def git(subcommand, output: :from_config)
        sh("git #{subcommand}", output: output)
      end

      def git!(subcommand, output: :from_config)
        sh!("git #{subcommand}", output: output)
      end

      def sh(command, output: :from_config)
        command_executor(output: output).run command
      end

      def sh!(command, output: :from_config)
        raise Verto::ExitError, command unless sh(command, output: output).success?
      end

      def command_options
        Verto.config.command_options
      end

      def before(&block)
        Verto.config.hooks << Hook.new(moment: :before, &block)
      end

      def after(&block)
        Verto.config.hooks << Hook.new(moment: :after, &block)
      end

      def on(moment, &block)
        deprecate('on', use: 'before_tag_creation')

        Verto.config.hooks << Hook.new(moment: moment, &block)
      end

      def before_command(command_name, &block)
        deprecate('before_command', use: 'before_command_tag_up')

        Verto.config.hooks << Hook.new(moment: "before_#{command_name}", &block)
      end

      def after_command(command_name, &block)
        deprecate('after_command', use: 'after_command_tag_up')

        Verto.config.hooks << Hook.new(moment: "after_#{command_name}", &block)
      end

      def before_command_tag_up(&block)
        Verto.config.hooks << Hook.new(moment: 'before_tag_up', &block)
      end

      def after_command_tag_up(&block)
        Verto.config.hooks << Hook.new(moment: 'after_tag_up', &block)
      end

      def before_tag_creation(&block)
        Verto.config.hooks << Hook.new(moment: 'before_tag_creation', &block)
      end

      # Start the flow to Update the CHANGELOG file
      # @param :with [Symbol] The strategy to search commit messages
      #   Options include:
      #   :merged_pull_requests_with_bracketed_labels -> Uses all PR merged commits after the last tag if they have the [***] pattern
      #   :commits_with_bracketed_labels              -> Uses all commits after the last tag if they have the [***] pattern (Exclude merge commits)
      #   :merged_pull_requests_messages              -> Uses all merged commit after the last tag
      #   :commit_messages                            -> Uses all commits after the last tag (Exclude merge commits)
      # @param :confirmation [Boolean] Adds a confirmation step before updating the CHANGELOG
      # @param filename [String] The CHANGELOG filename
      # @param message_pattern [Regexp] A regexp pattern to filter commit messages
      def update_changelog(with: :merged_pull_requests_with_bracketed_labels, confirmation: true, filename: 'CHANGELOG.md')
        permitted_moments = %w[before_tag_creation after_tag_up]
        unless permitted_moments.include? Verto.current_moment.to_s
          raise ExitError, 'update_changelog is only supported in before_tag_creation or after_command_tag_up'
        end

        UpdateChangelog.new.call(with: with,
                                 new_version: new_version,
                                 confirmation: confirmation,
                                 filename: filename)
      end

      def file(filepath)
        DSL::File.new(filepath)
      end

      def env(environment_name)
        ENV[environment_name]
      end

      # TODO: Use delegator
      def confirm(text)
        CliHelpers.confirm(text)
      end

      def error(text)
        stderr.puts text
      end

      def error!(text)
        error(text)

        raise Verto::ExitError
      end

      private

      def command_executor(output: :from_config)
        @executors ||= {
          from_config: Verto::SystemCommandExecutor.new,
          true => Verto::SystemCommandExecutor.new(stdout: $stdout, stderr: $stderr),
          false => Verto::SystemCommandExecutor.new(stdout: nil, stderr: nil)
        }

        @executors[output]
      end

      def stderr
        Verto.stderr
      end

      def tag_repository
        @tag_repository ||= TagRepository.new
      end

      def latest_semantic_version_for(filter)
        tag_version = tag_repository.latest(filter: TagFilter.for(filter))

        return SemanticVersion.new('0.0.0') unless tag_version

        SemanticVersion.new(tag_version)
      end

      def deprecate(current, use:)
        warn "[DEPRECATED] `#{current}` is deprecated and will be removed in a future release, use `#{use}` instead"
      end
    end
  end
end
