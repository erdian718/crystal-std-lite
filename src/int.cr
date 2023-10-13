# Int is the base type of all integer types.
struct Int
  # Signed integer types.
  alias Signed = Int8 | Int16 | Int32 | Int64 | Int128
  # Unsigned integer types.
  alias Unsigned = UInt8 | UInt16 | UInt32 | UInt64 | UInt128

  # :nodoc:
  #
  # TODO: Just for compatibility with the official standard library.
  alias Primitive = Signed | Unsigned

  # :nodoc:
  macro inherited
    {{ raise "Cannot inherit from Int" }}
  end

  # Returns a `Char` that has the unicode codepoint of `self`.
  #
  # Raises `ArgumentError` if this integer's value doesn't fit a char's range.
  def chr : Char
    return unsafe_chr if 0 <= self <= 0xD7FF || 0xE000 <= self <= Char::MAX_CODEPOINT
    raise ArgumentError.new("0x#{self.to_s(16)} out of char range")
  end

  def ===(char : Char)
    self === char.ord
  end

  def <=>(other : Int) : Int
    # Override `Number#<=>` because there's no `nil`.
    self > other ? 1 : (self < other ? -1 : 0)
  end

  {% for prefix in ["", "&"] %}
    # Returns the value of raising `self` to the power of *other*.
    #
    # Raises `ArgumentError` if *other* is negative:
    # if this is needed, either use a float base or a float exponent.
    def {{prefix.id}}**(other : Int) : self
      if other < 0
        raise ArgumentError.new "Cannot raise an integer to a negative integer power, use floats for that"
      end

      base = self
      result = self.class.new(1)
      loop do
        result {{prefix.id}}*= base if other.odd?
        other = other.unsafe_shr(1)
        return result if other <= 0
        base {{prefix.id}}*= base
      end
    end
  {% end %}

  # Returns the value of raising `self` to the power of *other*.
  def **(other : Float) : Float64
    to_f ** other
  end

  private def check_div_argument(other)
    raise DivisionByZeroError.new if other == 0
    {% begin %}
      if self < 0 && self == {{@type}}::MIN && other == -1
        raise ArgumentError.new "Overflow: {{@type}}::MIN / -1"
      end
    {% end %}
  end

  # Divides `self` by *other* using floored division.
  def //(other : Int) : self
    check_div_argument(other)
    result = self.unsafe_div(other)
    if (self < 0) != (other < 0) && !self.unsafe_mod(other).zero?
      result -= 1
    end
    result
  end

  # Returns `self` modulo *other*.
  #
  # This uses floored division.
  def %(other : Int) : self
    check_div_argument(other)
    result = self.unsafe_mod(other)
    if !result.zero? && (self < 0) != (other < 0)
      result += other
    end
    result
  end

  # Divides `self` by *other* using truncated division.
  def tdiv(other : Int) : self
    check_div_argument(other)
    unsafe_div(other)
  end

  # Returns `self` remainder *other*.
  #
  # This uses truncated division.
  def remainder(other : Int) : self
    check_div_argument(other)
    unsafe_mod(other)
  end

  def ceil : self
    self
  end

  def floor : self
    self
  end

  def trunc : self
    self
  end

  def round(mode : RoundingMode) : self
    self
  end

  def round_even : self
    self
  end

  def round_away : self
    self
  end

  def ~ : self
    self ^ -1
  end

  # Returns the result of shifting this number's bits *count* positions to the right.
  #
  # * If *count* is greater than the number of bits of this integer, returns 0
  # * If *count* is negative, a left shift is performed
  def >>(count : Int) : self
    if count < 0
      self.unsafe_shl(count.abs)
    else
      self.unsafe_shr(count)
    end
  end

  # Returns the result of shifting this number's bits *count* positions to the left.
  #
  # * If *count* is greater than the number of bits of this integer, returns 0
  # * If *count* is negative, a right shift is performed
  def <<(count : Int) : self
    if count < 0
      self.unsafe_shr(count.abs)
    else
      self.unsafe_shl(count)
    end
  end

  # Returns this number's *bit*th bit, starting with the least-significant.
  def bit(bit) : self
    self >> bit & 1
  end

  # Returns `true` if all bits in *mask* are set on `self`.
  def bits_set?(mask) : Bool
    (self & mask) == mask
  end

  # Returns the number of bits of this int value.
  def bit_length : Int
    x = self < 0 ? ~self : self
    8*sizeof(self) - x.leading_zeros_count
  end

  # :nodoc:
  def next_power_of_two : self
    one = self.class.new!(1)

    bits = sizeof(self) * 8
    shift = bits &- (self &- 1).leading_zeros_count
    if self.is_a?(Int::Signed)
      shift = 0 if shift >= bits &- 1
    else
      shift = 0 if shift == bits
    end

    result = one << shift
    result >= self ? result : raise OverflowError.new
  end

  # Returns the greatest common divisor of `self` and *other*.
  def gcd(other : self) : self
    u = self.abs
    v = other.abs
    return v if u == 0
    return u if v == 0

    shift = self.class.zero
    # Let shift := lg K, where K is the greatest power of 2
    # dividing both u and v.
    while (u | v) & 1 == 0
      shift &+= 1
      u = u.unsafe_shr 1
      v = v.unsafe_shr 1
    end
    while u & 1 == 0
      u = u.unsafe_shr 1
    end
    # From here on, u is always odd.
    loop do
      # remove all factors of 2 in v -- they are not common
      # note: v is not zero, so while will terminate
      while v & 1 == 0
        v = v.unsafe_shr 1
      end
      # Now u and v are both odd. Swap if necessary so u <= v,
      # then set v = v - u (which is even).
      u, v = v, u if u > v
      v &-= u
      break if v.zero?
    end
    # restore common factors of 2
    u.unsafe_shl shift
  end

  # Returns the least common multiple of `self` and *other*.
  def lcm(other : Int) : self
    (self // gcd(other) * other).abs
  end

  def divisible_by?(other : Number) : Bool
    remainder(other) == 0
  end

  def even? : Bool
    self & 1 == 0
  end

  def odd? : Bool
    self & 1 == 1
  end

  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.int(self)
  end

  def succ : self
    self + 1
  end

  def pred : self
    self - 1
  end

  def times(&block : self ->) : Nil
    i = self.class.zero
    while i < self
      yield i
      i &+= 1
    end
  end

  def times
    Steppable::StepIterator.new(self.zero, self, 1)
  end

  def upto(to : Number, &block : self ->) : Nil
    step(to: to, by: 1) { |i| yield i }
  end

  def upto(to : Number)
    step(to: to, by: 1)
  end

  # Calls the given block with each integer value from self down to `to`.
  def downto(to : Number, &block : self ->) : Nil
    step(to: to, by: -1) { |i| yield i }
  end

  # Get an iterator for counting down from self to `to`.
  def downto(to : Number)
    step(to: to, by: -1)
  end

  def to(to, &block : self ->) : Nil
    if self < to
      upto(to) { |i| yield i }
    elsif self > to
      downto(to) { |i| yield i }
    else
      yield self
    end
  end

  def to(to)
    self <= to ? upto(to) : downto(to)
  end

  # Appends a string representation of this integer to the given *io*.
  #
  # *base* specifies the radix of the written string,
  # and must be a number between 2 and 36.
  #
  # *precision* specifies the minimum number of digits in the written string.
  # If there are fewer digits than this number, the string is left-padded by zeros.
  # If `self` and *precision* are both zero, returns an empty string.
  def to_s(io : IO, base : Int = 10, *, precision : Int = 1, upcase : Bool = false) : Nil
    raise ArgumentError.new("Invalid base #{base}") unless 2 <= base <= 36
    raise ArgumentError.new("Precision must be non-negative") unless precision >= 0
    return if self.zero? && precision.zero?

    if upcase
      digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".to_unsafe
    else
      digits = "0123456789abcdefghijklmnopqrstuvwxyz".to_unsafe
    end

    value = self
    buffer = uninitialized UInt8[128]
    pos = buffer.size
    loop do
      pos -= 1
      buffer[pos] = digits[value.unsafe_mod(base).abs]
      value = value.unsafe_div(base)
      break if value.zero?
    end

    count = buffer.size - pos
    io << '-' if negative?
    (precision - count).times { io << '0' }
    io.write(buffer.to_slice[pos..])
  end

  # Returns a string representation of this integer.
  def to_s(base : Int = 10, *, precision : Int = 1, upcase : Bool = false) : String
    String.build do |io|
      to_s(io, base, precision: precision, upcase: upcase)
    end
  end

  # Writes this integer to the given *io* in the given *format*.
  #
  # See also: `IO#write_bytes`.
  def to_io(io : IO, format : IO::ByteFormat) : Nil
    format.encode(self, io)
  end

  # Reads an integer from the given *io* in the given *format*.
  #
  # See also: `IO#read_bytes`.
  def self.from_io(io : IO, format : IO::ByteFormat) : self
    format.decode(self, io)
  end

  # Counts `1`-bits in the binary representation of this integer.
  abstract def popcount : Int

  # Returns the number of trailing `0`-bits.
  abstract def trailing_zeros_count : Int
end

{% begin %}
  {% for bits in [8, 16, 32, 64, 128] %}
    struct Int{{bits}}
      MIN = 1_i{{bits}} << ({{bits}} - 1)
      MAX = ~MIN

      def self.new(value : String, base : Int = 10, whitespace : Bool = true, underscore : Bool = false, prefix : Bool = false, strict : Bool = true, leading_zero_is_octal : Bool = false) : self
        value.to_i{{bits}}(base: base, whitespace: whitespace, underscore: underscore, prefix: prefix, strict: strict, leading_zero_is_octal: leading_zero_is_octal)
      end

      def self.new(value) : self
        value.to_i{{bits}}
      end

      # Returns an `Int8` by invoking `to_i8!` on *value*.
      def self.new!(value) : self
        value.to_i{{bits}}!
      end

      def - : self
        0_i{{bits}} - self
      end

      # :nodoc:
      def neg_signed : self
        -self
      end

      # :nodoc:
      def abs_unsigned : self
        self < 0 ? 0_u{{bits}} &- self : to_u{{bits}}!
      end

      def popcount : Int{{bits}}
        Intrinsics.popcount{{bits}}(self)
      end

      def leading_zeros_count : Int{{bits}}
        Intrinsics.countleading{{bits}}(self, false)
      end

      def trailing_zeros_count : Int{{bits}}
        Intrinsics.counttrailing{{bits}}(self, false)
      end

      # Reverses the bits of `self`. the least significant bit becomes the most significant, and vice-versa.
      def bit_reverse : self
        Intrinsics.bitreverse{{bits}}(self).to_i{{bits}}!
      end

      # Swaps the bytes of `self`; a little-endian value becomes a big-endian value, and vice-versa.
      # The bit order within each byte is unchanged.
      def byte_swap : self
        {% if bits == 8 %}
          self
        {% else %}
          Intrinsics.bswap{{bits}}(self).to_i{{bits}}!
        {% end %}
      end

      # Returns the bitwise rotation of `self` *n* times in the most significant bit's direction.
      # Negative shifts are equivalent to `rotate_right(-n)`.
      def rotate_left(n : Int) : self
        Intrinsics.fshl{{bits}}(self, self, n.to_i{{bits}}!).to_i{{bits}}!
      end

      # Returns the bitwise rotation of `self` *n* times in the least significant bit's direction.
      # Negative shifts are equivalent to `rotate_left(-n)`.
      def rotate_right(n : Int) : self
        Intrinsics.fshr{{bits}}(self, self, n.to_i{{bits}}!).to_i{{bits}}!
      end
    end

    struct UInt{{bits}}
      MIN = 0_u{{bits}}
      MAX = ~MIN

      def self.new(value : String, base : Int = 10, whitespace : Bool = true, underscore : Bool = false, prefix : Bool = false, strict : Bool = true, leading_zero_is_octal : Bool = false) : self
        value.to_u{{bits}}(base: base, whitespace: whitespace, underscore: underscore, prefix: prefix, strict: strict, leading_zero_is_octal: leading_zero_is_octal)
      end

      def self.new(value) : self
        value.to_u{{bits}}
      end

      # Returns an `Int8` by invoking `to_i8!` on *value*.
      def self.new!(value) : self
        value.to_u{{bits}}!
      end

      def &- : self
        0_u{{bits}} &- self
      end

      # :nodoc:
      def neg_signed : Int{{bits}}
        0_i{{bits}} - self
      end

      # :nodoc:
      def abs_unsigned : self
        self
      end

      def abs : self
        self
      end

      def popcount : Int
        Intrinsics.popcount{{bits}}(self)
      end

      def leading_zeros_count : Int
        Intrinsics.countleading{{bits}}(self, false)
      end

      def trailing_zeros_count : Int
        Intrinsics.counttrailing{{bits}}(self, false)
      end

      # Reverses the bits of `self`; the least significant bit becomes the most significant, and vice-versa.
      def bit_reverse : self
        Intrinsics.bitreverse{{bits}}(self)
      end

      # Swaps the bytes of `self`; a little-endian value becomes a big-endian value, and vice-versa.
      # The bit order within each byte is unchanged.
      def byte_swap : self
        {% if bits == 8 %}
          self
        {% else %}
          Intrinsics.bswap{{bits}}(self)
        {% end %}
      end

      # Returns the bitwise rotation of `self` *n* times in the most significant bit's direction.
      # Negative shifts are equivalent to `rotate_right(-n)`.
      def rotate_left(n : Int) : self
        Intrinsics.fshl{{bits}}(self, self, n.to_u{{bits}}!)
      end

      # Returns the bitwise rotation of `self` *n* times in the least significant bit's direction.
      # Negative shifts are equivalent to `rotate_left(-n)`.
      def rotate_right(n : Int) : self
        Intrinsics.fshr{{bits}}(self, self, n.to_u{{bits}}!)
      end
    end
  {% end %}
{% end %}
