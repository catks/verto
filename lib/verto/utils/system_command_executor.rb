require 'open3'

module Verto
  class SystemCommandExecutor
    include Verto.import['project.path']

    class Result < Struct.new(:output, :error, :result)
      def success?
        @result.success?
      end

      def error?
        !success?
      end
    end
    Error = Class.new(StandardError)

    def run(command)
      Open3.popen3(in_path(command)) do |stdin, stdout, stderr, wait_thread|
        @output = stdout.read
        @error = stderr.read
        @result = wait_thread.value
      end

      Result.new(@output, @error, @result)
    end

    def run!(command)
      run(command)

      raise Error, @error unless @error.empty?
    end


    private

    def in_path(command)
      "cd #{path} && #{command}"
    end
  end
end
