# frozen_string_literal: true

require 'fileutils'

class TestRepo
  attr_accessor :path

  def initialize(path = Verto.root_path.join('tmp/test_repo'))
    FileUtils.mkdir_p(path)
    @path = path
  end

  def init!
    clear!
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
    run "git tag #{version}"
  end

  def commit!(message)
    run "git commit -m '#{message}' --allow-empty"
  end

  def merge_commit!(message)
    run 'git checkout -b test_merge'
    commit!('Test Commit')

    run 'git checkout master'

    run 'git merge --no-ff test_merge'
    run "git commit --amend -m '#{message}'"
    run 'git branch -D test_merge'
  end

  def checkout(branch)
    run "git checkout -b #{branch}"
  end

  def run(command)
    `cd #{@path} && #{command}`
  end
end
