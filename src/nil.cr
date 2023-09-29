# The `Nil` type has only one possible value: `nil`.
#
# `nil` is commonly used to represent the absence of a value.
struct Nil
  # Returns `0_u64`. Even though `Nil` is not a `Reference` type,
  # it is usually mixed with them to form nilable types so it's useful to have an object id for `nil`.
  def object_id : UInt64
    0_u64
  end

  # :nodoc:
  def crystal_type_id : Int32
    0
  end

  # Returns `true`: `Nil` has only one singleton value: `nil`.
  def ==(other : Nil) : Bool
    true
  end

  # Returns `true`: `Nil` has only one singleton value: `nil`.
  def same?(other : Nil) : Bool
    true
  end

  # Returns `false`.
  def same?(other : Reference) : Bool
    false
  end

  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.nil
  end

  # Doesn't write anything to the given `IO`.
  def to_s(io : IO) : Nil
    # Nothing to do
  end

  # Returns an empty string.
  def to_s : String
    ""
  end

  # Writes `"nil"` to the given `IO`.
  def inspect(io : IO) : Nil
    io << "nil"
  end

  # Returns `"nil"`.
  def inspect : String
    "nil"
  end

  # Doesn't yield to the block.
  #
  # See also: `Object#try`.
  def try(&block)
    self
  end

  # Raises `NilAssertionError`.
  #
  # If *message* is given, it is forwarded as error message of `NilAssertionError`.
  #
  # See also: `Object#not_nil!`.
  def not_nil!(message = nil) : NoReturn
    if message
      raise NilAssertionError.new(message)
    else
      raise NilAssertionError.new
    end
  end

  # Returns `self`.
  # This method enables to call the `presence` method (see `String#presence`) on a union with `Nil`.
  # The idea is to return `nil` when the value is `nil` or empty.
  def presence : Nil
    self
  end

  # Returns `self`.
  def clone
    self
  end
end
