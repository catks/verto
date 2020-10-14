require 'fileutils'

class TestRepo
  attr_accessor :path

  def initialize(path=Verto.root_path.join('tmp/test_repo'))
    FileUtils.mkdir_p(path)
    @path = path
  end

  def init!
    run 'git init'
    run 'touch test'
    run 'git add test'
    commit!('First')
  end

  def clear!
    run 'rm -rf * && rm -rf .git'
  end

  def reload!
    clear!
    init!
  end

  def tag!(version)
    run 'git tag version'
  end

  def commit!(message)
    run "git commit -m '#{message}' --allow-empty"
  end

  def checkout(branch)
    run "git checkout -b #{branch}"
  end

  def run(command)
    `cd #{@path} && #{command}`
  end
end
