class String
  unless "".respond_to?(:encoding)
    def encoding
      nil
    end
  end
  unless "".respond_to?(:force_encoding)
    def force_encoding(encoding)
      self
    end
  end
end