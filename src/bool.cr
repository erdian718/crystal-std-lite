# Bool has only two possible values: `true` and `false`.
struct Bool
  # Bitwise OR. Returns `true` if this bool or *other* is `true`, otherwise returns `false`.
  def |(other : Bool) : Bool
    self ? true : other
  end

  # Bitwise AND. Returns `true` if this bool and *other* are `true`, otherwise returns `false`.
  def &(other : Bool) : Bool
    self ? other : false
  end

  # Exclusive OR. Returns `true` if this bool is different from *other*, otherwise returns `false`.
  def ^(other : Bool) : Bool
    self != other
  end

  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.bool(self)
  end

  # Returns an integer derived from the boolean value, for interoperability with C-style booleans.
  #
  # The value is `1` for `true` and `0` for `false`.
  def to_unsafe : LibC::Int
    LibC::Int.new(self ? 1 : 0)
  end

  # Appends `"true"` for `true` and `"false"` for `false` to the given IO.
  def to_s(io : IO) : Nil
    io << to_s
  end

  # Returns `"true"` for `true` and `"false"` for `false`.
  def to_s : String
    self ? "true" : "false"
  end

  # Returns `self`.
  def clone : Bool
    self
  end
end
