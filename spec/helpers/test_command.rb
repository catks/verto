require 'open3'

class TestCommand
  Error = Class.new(StandardError)

  def initialize(command)
    @command = command
  end

  def run!
    Open3.popen3(@command) do |stdin, stdout, stderr, _|
      @output = stdout.read
      @error = stderr.read
    end

    raise Error, @error unless @error.empty?
  end
end
