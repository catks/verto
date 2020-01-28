require 'open3'

module Verto
  class SystemCommandExecutor
    include Verto.import['project.path']

    Error = Class.new(StandardError)

    def run(command)
      Open3.popen3(in_path(command)) do |stdin, stdout, stderr, _|
        @output = stdout.read
        @error = stderr.read
      end

      @output
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
