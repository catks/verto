module Verto
  class Template
    def self.render(template_name, to:)
      new(template_name).render(to: to)
    end

    def initialize(template_name)
      @template_name = template_name
    end

    def render(to:)
      path = Pathname.new(to)
      path.join(@template_name).write(template_content)
    end

    private

    def template_content
      @template_content = template_path.join(@template_name).read
    end

    def template_path
      Verto.root_path.join('lib/verto/utils/templates')
    end
  end
end
