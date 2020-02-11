module FileHelpers
  def file_content(filename)
    file(filename).readlines.first.chomp
  end

  def file(filename)
    file_helper_path.join(filename)
  end

  def file_helper_path=(path)
    @file_helper_path = path
  end

  def file_helper_path
    @file_helper_path || Verto.root_path.join(Verto.config.project.path)
  end
end
