# `Struct` is the base type of structs you create in your program.
#
# The standard library provides a useful `record` macro that allows you to create immutable structs with some fields,
# similar to a `Tuple` but using names instead of indices.
struct Struct
  # Returns `true` if this struct is equal to *other*.
  #
  # Both structs' instance vars are compared to each other.
  # Thus, two structs are considered equal if each of their instance variables are equal.
  # Subclasses should override this method to provide specific equality semantics.
  def ==(other : self) : Bool
    {% for ivar in @type.instance_vars %}
      return false unless @{{ivar.id}} == other.@{{ivar.id}}
    {% end %}
    true
  end

  # :ditto:
  def ==(other) : Bool
    false
  end

  # See `Object#hash(hasher)`
  def hash(hasher)
    {% for ivar in @type.instance_vars %}
      hasher = @{{ivar.id}}.hash(hasher)
    {% end %}
    hasher
  end

  # Appends this struct's name and instance variables names and values to the given IO.
  def to_s(io : IO) : Nil
    io << self.class.name << '('

    {% for ivar, i in @type.instance_vars %}
      {% if i > 0 %}
        io << ", "
      {% end %}
      io << "@{{ivar.id}}="
      @{{ivar.id}}.to_s(io)
    {% end %}

    io << ')'
  end
end
