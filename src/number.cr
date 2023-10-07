# The top-level number type.
# It has and only two subclasses: `Int` and `Float`.
struct Number
  include Comparable(Number)
  include Steppable

  # :nodoc:
  #
  # In this library, `Number` is always primitive, and this alias is reserved only for compatibility.
  alias Primitive = Int::Primitive | Float::Primitive

  macro inherited
    {{ raise "Cannot inherit from Number" }}
  end

  # Returns the value zero in the respective type.
  def self.zero : self
    new(0)
  end

  # Returns `true` if `self` is equal to zero.
  def zero? : Bool
    self == 0
  end

  # Returns `true` if `self` is greater than zero.
  def positive? : Bool
    self > 0
  end

  # Returns `true` if `self` is less than zero.
  def negative? : Bool
    self < 0
  end

  # Returns the sign of this number as an `Int32`.
  # * `1` if this number is positive.
  # * `-1` if this number is negative.
  # * `0` if this number is zero or nan.
  def sign : Int32
    self > 0 ? 1 : (self < 0 ? -1 : 0)
  end

  # Returns the absolute value of this number.
  def abs : self
    self < 0 ? -self : self
  end

  # Returns the square of `self`.
  def abs2 : self
    self * self
  end

  # Returns a `Tuple` of two elements containing the quotient and modulus obtained by dividing `self` by *other*.
  def divmod(other)
    {self // other, self % other}
  end

  # Returns `self`.
  def + : self
    self
  end

  # Divides `self` by *other* using floored division.
  #
  # The result will be of the same type as `self`.
  def //(other)
    self.class.new((self / other).floor)
  end

  # The comparison operator.
  def <=>(other) : Int32?
    return 0 if self == other
    return 1 if self > other
    return -1 if self < other
    nil
  end

  # Returns self converted to Int.
  # Raises OverflowError in case of overflow.
  #
  # NOTE: The return value type is the default integer type,
  # depending on the platform and compiler version.
  def to_i : Int
    to_i32
  end

  # Returns self converted to unsigned Int.
  #
  # NOTE: The return value type is the default unsigned integer type,
  # depending on the platform and compiler version.
  def to_u : Int
    to_u32
  end

  # Returns self converted to Float.
  #
  # NOTE: The return value type is the default float type,
  # depending on the platform and compiler version.
  def to_f : Float
    to_f64
  end

  # Returns self converted to Int.
  #
  # NOTE: The return value type is the default integer type,
  # depending on the platform and compiler version.
  def to_i! : Int
    to_i32!
  end

  # Returns self converted to unsigned Int.
  #
  # NOTE: The return value type is the default unsigned integer type,
  # depending on the platform and compiler version.
  def to_u! : Int
    to_u32!
  end

  # Returns self converted to Float.
  #
  # NOTE: The return value type is the default float type,
  # depending on the platform and compiler version.
  def to_f! : Float
    to_f64!
  end

  # :nodoc:
  macro expand_div(rhs_types, result_type)
    {% for rhs in rhs_types %}
      @[AlwaysInline]
      def /(other : {{rhs}}) : {{result_type}}
        {{result_type}}.new(self) / {{result_type}}.new(other)
      end
    {% end %}
  end

  # Creates an `Array` of `self` with the given values,
  # which will be casted to this type with the `new` method.
  macro [](*numbers)
    Array({{@type}}).build({{numbers.size}}) do |%buffer|
      {% for number, i in numbers %}
        %buffer[{{i}}] = {{@type}}.new({{number}})
      {% end %}
      {{numbers.size}}
    end
  end

  # Creates a `Slice` of `self` with the given values,
  # which will be casted to this type with the `new` method.
  macro slice(*numbers, read_only = false)
    %slice = Slice({{@type}}).new({{numbers.size}}, read_only: {{read_only}})
    {% for number, i in numbers %}
      %slice[{{i}}] = {{@type}}.new({{number}})
    {% end %}
    %slice
  end

  # Creates a `StaticArray` of `self` with the given values,
  # which will be casted to this type with the `new` method.
  macro static_array(*numbers)
    %array = uninitialized StaticArray({{@type}}, {{numbers.size}})
    {% for number, i in numbers %}
      %array[{{i}}] = {{@type}}.new({{number}})
    {% end %}
    %array
  end

  # Performs a `#step` in the direction of the *limit*.
  def step(*, to limit = nil, exclusive : Bool = false, &) : Nil
    direction = limit <=> self if limit
    step = direction.try(&.sign) || 1
    step(to: limit, by: step, exclusive: exclusive) do |x|
      yield x
    end
  end

  # :ditto:
  def step(*, to limit = nil, exclusive : Bool = false)
    direction = limit <=> self if limit
    step = direction.try(&.sign) || 1
    step(to: limit, by: step, exclusive: exclusive)
  end

  # Specifies rounding behaviour for numerical operations capable of discarding precision.
  enum RoundingMode
    # Rounds towards the nearest integer. If both neighboring integers are equidistant,
    # rounds towards the even neighbor (Banker's rounding).
    TIES_EVEN

    # Rounds towards the nearest integer. If both neighboring integers are equidistant,
    # rounds away from zero.
    TIES_AWAY

    # Rounds towards zero (truncate).
    TO_ZERO

    # Rounds towards positive infinity (ceil).
    TO_POSITIVE

    # Rounds towards negative infinity (floor).
    TO_NEGATIVE
  end

  # Rounds `self` to an integer value using rounding *mode*.
  #
  # The rounding *mode* controls the direction of the rounding.
  # The default is `RoundingMode::TIES_EVEN` which rounds to the nearest integer,
  # with ties being rounded to the even neighbor.
  def round(mode : RoundingMode = :ties_even) : self
    case mode
    in .to_zero?
      trunc
    in .to_positive?
      ceil
    in .to_negative?
      floor
    in .ties_away?
      round_away
    in .ties_even?
      round_even
    end
  end

  # Rounds this number to a given precision.
  #
  # Rounds to the specified number of *digits* after the decimal place in base *base*.
  #
  # The rounding *mode* controls the direction of the rounding.
  # The default is `RoundingMode::TIES_EVEN` which rounds to the nearest integer,
  # with ties being rounded to the even neighbor.
  def round(digits : Number, base = 10, *, mode : RoundingMode = :ties_even) : self
    if digits < 0
      multiplier = base.to_f64 ** digits.abs
      shifted = self / multiplier
    else
      multiplier = base.to_f64 ** digits
      shifted = self * multiplier
    end

    rounded = shifted.round(mode)
    if digits < 0
      result = rounded * multiplier
    else
      result = rounded / multiplier
    end

    self.class.new(result)
  end

  # Keeps *digits* significant digits of this number in the given *base*.
  def significant(digits, base = 10) : self
    raise ArgumentError.new "digits should be non-negative" if digits < 0
    return self if zero?

    if base == 10
      log = Math.log10(self.abs)
    elsif base == 2
      log = Math.log2(self.abs)
    else
      log = Math.log2(self.abs) / Math.log2(base)
    end

    x = self.to_f64
    exponent = (log - digits + 1).floor
    if exponent < 0
      y = base ** -exponent
      value = (x * y).round / y
    else
      y = base ** exponent
      value = (x / y).round * y
    end

    self.class.new(value)
  end
end
