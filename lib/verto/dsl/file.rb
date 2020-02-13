module Verto
  module DSL
    class File
      def initialize(filename, path: Verto.config.project.path)
        @filename = filename
        @path = Pathname.new(path)
      end

      def replace(to_match, to_replace)
        content = file.read

        file.open('w') do |f|
          f << content.sub(to_match, to_replace)
        end
      end

      def replace_all(to_match, to_replace)
        content = file.read

        file.open('w') do |f|
          f << content.gsub(to_match, to_replace)
        end
      end

      def append(content)
        file.open('a') do |f|
          f << content
        end
      end

      def prepend(content)
        file_content = file.read

        file.open('w') do |f|
          f << (content + file_content)
        end
      end

      alias_method :gsub, :replace_all
      alias_method :sub, :replace

      private

      def file
        @path.join(@filename)
      end
    end
  end
end
