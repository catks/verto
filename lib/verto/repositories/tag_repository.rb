module Verto
  class TagRepository
    include Verto.import[executor: 'system_command_executor']

    def latest
      all.last
    end

    def create!(tag)
      # TODO: Implements tag in other commits
      executor.run! "git tag #{tag}"
    end

    def all
      results = executor.run "git tag | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)*' | sed 's/\([0-9]\.[0-9]\.[0-9]$\)/\1-zzzzzzzzzz/' | sort -V |  sed 's/-zzzzzzzzzz//' | cat"

      results.split
    end
  end
end
