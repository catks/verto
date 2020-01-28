module Verto
  class MainCommand < BaseCommand
    desc "tag SUBCOMMAND ...ARGS", "manage the repository tags"
    subcommand 'tag', Verto::TagCommand
  end
end
