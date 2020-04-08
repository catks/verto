module Verto
  class MainCommand < BaseCommand
    desc "tag SUBCOMMAND ...ARGS", "manage the repository tags"
    subcommand 'tag', Verto::TagCommand

    desc "init", "Initialize a Vertofile in your repository"

    option :path, type: :string, default: nil
    def init
      path = options[:path] || Verto.config.project.path

      validate_current_vertofile!(path)

      Template.render('Vertofile', to: path)
    end

    desc "version", "Show Verto version"

    def version
      Verto.stdout.puts Verto::VERSION
    end

    private

    def validate_current_vertofile!(path)
      command_error!(
        <<~ERROR
         Project already have a Vertofile.
         If you want to generate a new with verto init, delete the current one with: `rm Vertofile`
        ERROR
      ) if Pathname.new(path).join('Vertofile').exist?
    end
  end
end
