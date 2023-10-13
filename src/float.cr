require "c/stdio"
require "c/string"

# Float is the base type of all floating point numbers.
struct Float
  # :nodoc:
  #
  # TODO: Just for compatibility with the official standard library.
  alias Primitive = Float32 | Float64

  # :nodoc:
  macro inherited
    {{ raise "Cannot inherit from Float" }}
  end

  # Returns the opposite number of `self`.
  def - : self
    self.class.zero - self
  end

  {% for op in %w(+ - *) %}
    # Performs `{{op.id}}` operation.
    def {{op.id}}(other : Number) : self
      self {{op.id}} self.class.new(other)
    end
  {% end %}

  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.float(self)
  end

  # Writes this float to the given *io* in the given *format*.
  # See also: `IO#write_bytes`.
  def to_io(io : IO, format : IO::ByteFormat) : Nil
    format.encode(self, io)
  end

  # Reads a float from the given *io* in the given *format*.
  # See also: `IO#read_bytes`.
  def self.from_io(io : IO, format : IO::ByteFormat) : self
    format.decode(self, io)
  end
end

struct Float32
  # Smallest finite value.
  MIN = -3.40282347e+38_f32
  # Largest finite value.
  MAX = 3.40282347e+38_f32
  # The machine epsilon.
  EPSILON = 1.19209290e-07_f32
  # The number of decimal digits that can be represented without losing precision.
  DIGITS = 6
  # The radix or integer base used by the internal representation.
  RADIX = 2
  # The number of digits that can be represented without losing precision (in base RADIX).
  MANT_DIGITS = 24
  # The minimum possible normal power of 2 exponent.
  MIN_EXP = -125
  # The maximum possible normal power of 2 exponent.
  MAX_EXP = 128
  # The minimum possible power of 10 exponent.
  MIN_10_EXP = -37
  # The maximum possible power of 10 exponent.
  MAX_10_EXP = 38
  # Smallest representable positive value.
  MIN_POSITIVE = 1.17549435e-38_f32
end

struct Float64
  # Smallest finite value.
  MIN = -1.7976931348623157e+308_f64
  # Largest finite value.
  MAX = 1.7976931348623157e+308_f64
  # The machine epsilon.
  EPSILON = 2.2204460492503131e-16_f64
  # The number of decimal digits that can be represented without losing precision.
  DIGITS = 15
  # The radix or integer base used by the internal representation.
  RADIX = 2
  # The number of digits that can be represented without losing precision (in base RADIX).
  MANT_DIGITS = 53
  # The minimum possible normal power of 2 exponent.
  MIN_EXP = -1021
  # The maximum possible normal power of 2 exponent.
  MAX_EXP = 1024
  # The minimum possible power of 10 exponent.
  MIN_10_EXP = -307
  # The maximum possible power of 10 exponent.
  MAX_10_EXP = 308
  # Smallest representable positive value.
  MIN_POSITIVE = 2.2250738585072014e-308_f64
end

{% for bits in [32, 64] %}
  struct Float{{bits}}
    # The not-a-number value.
    NAN = (0_f{{bits}} / 0_f{{bits}}).as(Float{{bits}})
    # The infinity value.
    INFINITY = (1_f{{bits}} / 0_f{{bits}}).as(Float{{bits}})

    # Returns a `Float{{bits}}` by invoking `to_f{{bits}}` on *value*.
    def self.new(value) : self
      value.to_f{{bits}}
    end

    # Returns a `Float{{bits}}` by invoking `to_f{{bits}}!` on *value*.
    def self.new!(value) : self
      value.to_f{{bits}}!
    end

    # Returns a `Float{{bits}}` by invoking `String#to_f{{bits}}` on *value*.
    def self.new(value : String, whitespace : Bool = true, strict : Bool = true) : self
      value.to_f{{bits}}(whitespace: whitespace, strict: strict)
    end

    # :nodoc:
    def **(other : self) : self
      LibM.pow_f{{bits}}(self, other)
    end

    # Returns the greatest `Float{{bits}}` that is less than `self`.
    def prev_float : self
      LibM.nextafter_f{{bits}}(self, -INFINITY)
    end

    # Returns the least `Float{{bits}}` that is greater than `self`.
    def next_float : self
      LibM.nextafter_f{{bits}}(self, INFINITY)
    end

    # Rounds towards zero.
    def trunc : self
      LibM.trunc_f{{bits}}(self)
    end

    # Rounds towards positive infinity.
    def ceil : self
      LibM.ceil_f{{bits}}(self)
    end

    # Rounds towards negative infinity.
    def floor : self
      LibM.floor_f{{bits}}(self)
    end

    # Rounds towards the nearest integer.
    #
    # If both neighboring integers are equidistant, rounds towards the even neighbor.
    def round_even : self
      LibM.rint_f{{bits}}(self)
    end

    # Rounds towards the nearest integer.
    #
    # If both neighboring integers are equidistant, rounds away from zero.
    def round_away : self
      LibM.round_f{{bits}}(self)
    end

    # Prints the number to *io*.
    def to_s(io : IO) : Nil
      if nan?
        io << "NaN"
      elsif self > MAX
        io << "Infinity"
      elsif self < MIN
        io << "-Infinity"
      else
        buffer = uninitialized UInt8[32]
        n = LibC.snprintf(buffer.to_unsafe, buffer.size, "%.16g", self)
        io.write(buffer.to_slice[0, n])
      end
    end
  end
{% end %}
