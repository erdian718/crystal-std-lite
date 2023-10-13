# The `Comparable` mixin is used by classes whose objects may be ordered.
#
# Including types must provide an `<=>` method.
# `Comparable` uses `<=>` to implement the conventional comparison operators.
# All of these return `false` when `<=>` returns `nil`.
#
# NOTE: Returning `nil` is only useful when defining a partial comparable relationship.
# If none of the values of a type are comparable between each other,
# `Comparable` shouldn't be included.
module Comparable(T)
  # The comparison operator, returns:
  # - a negative number if `self` is less than *other*.
  # - a positive number if `self` is greater than *other*.
  # - `0` if `self` is equal to *other*.
  # - `nil` if `self` and *other* are not comparable.
  abstract def <=>(other : T)

  # Returns true if `self` is less than *other*.
  def <(other : T) : Bool
    cmp = self <=> other
    cmp ? cmp < 0 : false
  end

  # Returns true if `self` is less than or equal to *other*.
  def <=(other : T) : Bool
    cmp = self <=> other
    cmp ? cmp <= 0 : false
  end

  # Returns true if `self` is equal to *other*.
  def ==(other : T) : Bool
    cmp = self <=> other
    cmp ? cmp == 0 : false
  end

  # Returns true if `self` is greater than *other*.
  def >(other : T) : Bool
    cmp = self <=> other
    cmp ? cmp > 0 : false
  end

  # Returns true if `self` is greater than or equal to *other*.
  def >=(other : T) : Bool
    cmp = self <=> other
    cmp ? cmp >= 0 : false
  end

  # Clamps a value between *min* and *max*.
  def clamp(min, max)
    return max if !max.nil? && self > max
    return min if !min.nil? && self < min
    self
  end

  # Clamps a value within *range*.
  def clamp(range : Range)
    raise ArgumentError.new("Can't clamp an exclusive range") if !range.end.nil? && range.exclusive?
    clamp(range.begin, range.end)
  end
end
