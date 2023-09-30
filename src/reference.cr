{% if flag?(:preview_mt) %}
  require "crystal/thread_local_value"
{% end %}

# `Reference` is the base class of classes you define in your program.
#
# A reference type is passed by reference: when you pass it to methods,
# return it from methods or assign it to variables, a pointer is actually passed.
#
# Invoking `new` on a `Reference` allocates a new instance on the heap.
# The instance's memory is automatically garbage-collected.
class Reference
  # Returns `true` if this reference is the same as *other*.
  def ==(other : self) : Bool
    same?(other)
  end

  # :ditto:
  def ==(other) : Bool
    false
  end

  # Returns `true` if this reference is the same as *other*.
  def same?(other : Reference) : Bool
    object_id == other.object_id
  end

  # :ditto:
  def same?(other : Nil) : Bool
    false
  end

  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.reference(self)
  end

  # Returns a shallow copy of this object.
  #
  # This allocates a new object and copies the contents of `self` into it.
  def dup
    {% if @type.abstract? %}
      # This shouldn't happen, as the type is abstract,
      # but we need to avoid the allocate invocation below
      raise "Can't dup {{@type}}"
    {% else %}
      dup = self.class.allocate
      dup.as(Void*).copy_from(self.as(Void*), instance_sizeof(self))
      GC.add_finalizer(dup) if dup.responds_to?(:finalize)
      dup
    {% end %}
  end

  # Appends a short String representation of this object which includes its class name and its object address.
  def to_s(io : IO) : Nil
    io << "#<" << self.class.name << ":0x"
    object_id.to_s(io, 16)
    io << '>'
  end

  # Appends a String representation of this object which includes its class name,
  # its object address and the values of all instance variables.
  def inspect(io : IO) : Nil
    io << "#<" << self.class.name << ":0x"
    object_id.to_s(io, 16)

    {% for ivar, i in @type.instance_vars %}
      {% if i > 0 %}
        io << ','
      {% end %}
      io << " @{{ivar.id}}="
      @{{ivar.id}}.to_s(io)
    {% end %}

    io << '>'
  end

  # :nodoc:
  module ExecRecursive
    # NOTE: can't use `Set` here because of prelude require order
    alias Registry = Hash({UInt64, Symbol}, Nil)

    {% if flag?(:preview_mt) %}
      @@exec_recursive = Crystal::ThreadLocalValue(Registry).new
    {% else %}
      @@exec_recursive = Registry.new
    {% end %}

    def self.hash
      {% if flag?(:preview_mt) %}
        @@exec_recursive.get { Registry.new }
      {% else %}
        @@exec_recursive
      {% end %}
    end
  end

  private def exec_recursive(method, &)
    hash = ExecRecursive.hash
    key = {object_id, method}
    hash.put(key, nil) do
      yield
      hash.delete(key)
      return true
    end
    false
  end

  # :nodoc:
  module ExecRecursiveClone
    alias Registry = Hash(UInt64, UInt64)

    {% if flag?(:preview_mt) %}
      @@exec_recursive = Crystal::ThreadLocalValue(Registry).new
    {% else %}
      @@exec_recursive = Registry.new
    {% end %}

    def self.hash
      {% if flag?(:preview_mt) %}
        @@exec_recursive.get { Registry.new }
      {% else %}
        @@exec_recursive
      {% end %}
    end
  end

  # Helper method to perform clone by also checking recursiveness.
  # When clone is wanted, call this method.
  private def exec_recursive_clone(&)
    hash = ExecRecursiveClone.hash
    clone_object_id = hash[object_id]?
    unless clone_object_id
      clone_object_id = yield(hash).object_id
      hash.delete(object_id)
    end
    Pointer(Void).new(clone_object_id).as(self)
  end
end
