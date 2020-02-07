module Verto
  class TagRepository
    include Verto.import[executor: 'system_command_executor']

    def latest(filter: nil)
      all(filter: filter).last
    end

    def create!(tag)
      # TODO: Implements tag in other commits
      executor.run! "git tag #{tag}"
    end

    def all(filter: nil)
      results = executor.run("git tag | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(-.+\.[0-9]+)*' | sed 's/\([0-9]\.[0-9]\.[0-9]$\)/\1-zzzzzzzzzz/' | sort -V |  sed 's/-zzzzzzzzzz//' | cat").output.split

      filter ?  results.select { |tag| tag.match?(filter) } : results
    end
  end
end
