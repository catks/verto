# frozen_string_literal: true

require 'open3'

module Verto
  class SystemCommandExecutor
    include Verto.import['project.path', 'stdout', 'stderr']

    Result = Struct.new(:output, :error, :result) do
      def success?
        result.success?
      end

      def error?
        !success?
      end
    end
    Error = Class.new(StandardError)

    def run(command)
      stderr&.puts running_log(command, path)

      Open3.popen3(command, chdir: path.to_s) do |_, stdout, stderr, wait_thread|
        @output = stdout.read
        @error = stderr.read
        @result = wait_thread.value
      end

      stdout << @output if stdout
      stderr << @error if stderr

      Result.new(@output, @error, @result)
    end

    def run!(command)
      result = run(command)

      raise Error, @error unless @error.empty?

      result
    end

    private

    def running_log(command, path)
      log = "Running: #{command}"
      log = "#{log} (in #{path})" if path != './'
      log
    end
  end
end
