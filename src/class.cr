class Class
  # Returns whether this class is the same as *other*.
  def ==(other : Class) : Bool
    crystal_type_id == other.crystal_type_id
  end

  def ===(other) : Bool
    other.is_a?(self)
  end

  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.class(self)
  end

  # Returns whether this class inherits or includes *other*.
  def <(other : T.class) : Bool forall T
    {{ @type < T }}
  end

  # Returns whether this class inherits or includes *other*, or is equal to *other*.
  def <=(other : T.class) : Bool forall T
    {{ @type <= T }}
  end

  # Returns whether *other* inherits or includes `self`.
  def >(other : T.class) : Bool forall T
    {{ @type > T }}
  end

  # Returns whether *other* inherits or includes `self`, or is equal to `self`.
  def >=(other : T.class) forall T
    {{ @type >= T }}
  end

  # Returns the union type of `self` and *other*.
  def self.|(other : U.class) forall U
    t = uninitialized self
    u = uninitialized U
    typeof(t, u)
  end

  # Returns `true` if `nil` is an instance of this type.
  def nilable? : Bool
    {{ @type >= Nil }}
  end

  # Casts *other* to this class.
  #
  # This is the same as using `as`, but allows the class to be passed around as an argument.
  def cast(other) : self
    other.as(self)
  end

  # Returns the name of this class.
  def name : String
    {{ @type.name.stringify }}
  end

  # Prints class name to *io*.
  def to_s(io : IO) : Nil
    io << name
  end

  # Returns `self`.
  def dup
    self
  end
end
