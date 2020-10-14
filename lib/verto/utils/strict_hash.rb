class StrictHash < Hash
  def initialize(hash, default_proc: nil)
    super()
    self.default_proc = default_proc if default_proc
    merge!(hash)
  end
end
