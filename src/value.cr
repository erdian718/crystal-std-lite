# `Value` is the base type of the primitive types (`Nil`, `Bool`, `Char`, `Number`),
# `Symbol`, `Pointer`, `Tuple`, `StaticArray` and all structs.
#
# A `Value` is passed by value: when you pass it to methods,
# return it from methods or assign it to variables,
# a copy of the value is actually passed.
struct Value
  # Returns `false`.
  def ==(other) : Bool
    false
  end

  # Returns a shallow copy of this object.
  #
  # Because `Value` is a value type, this method returns `self`,
  # which already involves a shallow copy of this object because value types are passed by value.
  def dup : self
    self
  end
end
