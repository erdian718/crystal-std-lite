# `Object` is the base type of all Crystal objects.
class Object
  # Returns `true` if this object is equal to *other*.
  #
  # Subclasses override this method to provide class-specific meaning.
  abstract def ==(other)

  # Returns `true` if this object is not equal to *other*.
  #
  # By default this method is implemented as `!(self == other)`
  # so there's no need to override this unless there's a more efficient way to do it.
  def !=(other)
    !(self == other)
  end

  # Pattern match.
  #
  # Overridden by descendants to provide meaningful pattern-match semantics.
  def =~(other)
    nil
  end

  # Shortcut to `!(self =~ other)`.
  def !~(other)
    !(self =~ other)
  end

  # Case equality.
  #
  # The `===` method is used in a `case ... when ... end` expression.
  # Object simply implements `===` by invoking `==`,
  # but subclasses can override it to provide meaningful case-equality semantics.
  def ===(other)
    self == other
  end

  # Appends this object's value to *hasher*, and returns the modified *hasher*.
  #
  # Usually the macro `def_hash` can be used to generate this method.
  # Otherwise, invoke `hash(hasher)` on each object's instance variables to accumulate the result.
  abstract def hash(hasher)

  # Generates an `UInt64` hash value for this object.
  #
  # This method must have the property that `a == b` implies `a.hash == b.hash`.
  #
  # The hash value is used along with `==` by the `Hash` class to determine if two objects reference the same hash key.
  #
  # NOTE: Subclasses must not override this method. Instead, they must define `hash(hasher)`,
  # though usually the macro `def_hash` can be used to generate this method.
  def hash
    hash(Crystal::Hasher.new).result
  end

  # Prints to *io* a nicely readable and concise string representation of this object,
  # typically intended for users.
  #
  # NOTE: Thus implementations must not interpolate `self` in a string literal or call `io << self` which both would lead to an endless loop.
  #
  # Also see `#inspect(IO)`.
  abstract def to_s(io : IO) : Nil

  # Returns a nicely readable and concise string representation of this object,
  # typically intended for users.
  #
  # NOTE: This method should usually **not** be overridden.
  # It delegates to `#to_s(IO)` which can be overridden for custom implementations.
  #
  # Also see `#inspect`.
  def to_s : String
    String.build do |io|
      to_s(io)
    end
  end

  # Prints to *io* an unambiguous and information-rich string representation of this object,
  # typically intended for developers.
  #
  # It is similar to `#to_s(IO)`, but often provides more information.
  # Ideally, it should contain sufficient information to be able to recreate an object with the same value.
  #
  # For types that don't provide a custom implementation of this method,
  # default implementation delegates to `#to_s(IO)`.
  def inspect(io : IO) : Nil
    to_s(io)
  end

  # Returns an unambiguous and information-rich string representation of this object,
  # typically intended for developers.
  #
  # NOTE: This method should usually **not** be overridden.
  # It delegates to `#inspect(IO)` which can be overridden for custom implementations.
  #
  # Also see `#to_s`.
  def inspect : String
    String.build do |io|
      inspect(io)
    end
  end

  # Pretty prints `self` into the given printer.
  #
  # By default appends a text that is the result of invoking `#inspect` on `self`.
  # Subclasses should override for custom pretty printing.
  def pretty_print(pp : PrettyPrint) : Nil
    pp.text(inspect)
  end

  # Returns a pretty printed version of `self`.
  def pretty_inspect(width = 79, newline = "\n", indent = 0) : String
    String.build do |io|
      PrettyPrint.format(self, io, width, newline, indent)
    end
  end

  # Yields `self` to the block, and then returns `self`.
  #
  # The primary purpose of this method is to "tap into" a method chain,
  # in order to perform operations on intermediate results within the chain.
  def tap(&)
    yield self
    self
  end

  # Yields `self`. `Nil` overrides this method and doesn't yield.
  #
  # This method is useful for dealing with nilable types,
  # to safely perform operations only when the value is not `nil`.
  def try(&)
    yield self
  end

  # Returns `true` if `self` is included in the *collection* argument.
  def in?(collection) : Bool
    collection.includes?(self)
  end

  # :ditto:
  def in?(*values) : Bool
    values.includes?(self)
  end

  # Returns `self`.
  #
  # `Nil` overrides this method and raises `NilAssertionError`, see `Nil#not_nil!`.
  #
  # This method can be used to remove `Nil` from a union type.
  # However, it should be avoided if possible and is often considered a code smell.
  # Usually, you can write code in a way that the compiler can safely exclude `Nil` types.
  # `not_nil!` is only meant as a last resort when there's no other way to explain this to the compiler.
  # Either way, consider instead raising a concrete exception with a descriptive message.
  def not_nil!
    self
  end

  # :ditto:
  #
  # *message* has no effect. It is only used by `Nil#not_nil!(message = nil)`.
  def not_nil!(message)
    # FIXME: the above param-less overload cannot be expressed as an optional parameter here,
    # because that would copy the receiver if it is a struct.
    # see https://github.com/crystal-lang/crystal/issues/13263#issuecomment-1492885817 and also #13265
    self
  end

  # Returns `self`.
  def itself : self
    self
  end

  # Returns a shallow copy ("duplicate") of this object.
  #
  # In order to create a new object with the same value as an existing one, there are two possible routes:
  #
  # * create a *shallow copy* (`#dup`).
  # * create a *deep copy* (`#clone`).
  #
  # A shallow copy is only one level deep whereas a deep copy copies everything below.
  #
  # The `#clone` method can't be defined on `Object`.
  # It's not generically available for every type because cycles could be involved,
  # and the clone logic might not need to clone everything.
  abstract def dup

  # Unsafely reinterprets the bytes of an object as being of another `type`.
  #
  # This method is useful to treat a type that is represented as a chunk of bytes as another type where those bytes convey useful information.
  #
  # NOTE: This method is **unsafe** because it behaves unpredictably when the given `type` doesn't have the same bytesize as the receiver,
  # or when the given `type` representation doesn't semantically match the underlying bytes.
  # Because `unsafe_as` is a regular method, unlike the pseudo-method `as`,
  # you can't specify some types in the type grammar using a short notation.
  def unsafe_as(type : T.class) : T forall T
    x = self
    pointerof(x).as(T*).value
  end

  {% for prefixes in [{"", "", "@", "#"}, {"class_", "self.", "@@", "."}] %}
    {%
      macro_prefix = prefixes[0].id
      method_prefix = prefixes[1].id
      var_prefix = prefixes[2].id
      doc_prefix = prefixes[3].id
    %}

    # Defines getter methods for each of the given arguments.
    macro {{macro_prefix}}getter(*names, &block)
      \{% if block %}
        \{% if names.size != 1 %}
          \{{ raise "Only one argument can be passed to `getter` with a block" }}
        \{% end %}

        \{% name = names[0] %}

        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name.var.id}} : \{{name.type}}?

          def {{method_prefix}}\{{name.var.id}} : \{{name.type}}
            if (value = {{var_prefix}}\{{name.var.id}}).nil?
              {{var_prefix}}\{{name.var.id}} = \{{yield}}
            else
              value
            end
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}
            if (value = {{var_prefix}}\{{name.id}}).nil?
              {{var_prefix}}\{{name.id}} = \{{yield}}
            else
              value
            end
          end
        \{% end %}
      \{% else %}
        \{% for name in names %}
          \{% if name.is_a?(TypeDeclaration) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.var.id}} : \{{name.type}}
              {{var_prefix}}\{{name.var.id}}
            end
          \{% elsif name.is_a?(Assign) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.target.id}}
              {{var_prefix}}\{{name.target.id}}
            end
          \{% else %}
            def {{method_prefix}}\{{name.id}}
              {{var_prefix}}\{{name.id}}
            end
          \{% end %}
        \{% end %}
      \{% end %}
    end

    # Defines raise-on-nil and nilable getter methods for each of the given arguments.
    macro {{macro_prefix}}getter!(*names)
      \{% for name in names %}
        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name}}?

          def {{method_prefix}}\{{name.var.id}}? : \{{name.type}}?
            {{var_prefix}}\{{name.var.id}}
          end

          def {{method_prefix}}\{{name.var.id}} : \{{name.type}}
            if (value = {{var_prefix}}\{{name.var.id}}).nil?
              ::raise NilAssertionError.new("\{{@type}}\{{"{{doc_prefix}}".id}}\{{name.var.id}} cannot be nil")
            else
              value
            end
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}?
            {{var_prefix}}\{{name.id}}
          end

          def {{method_prefix}}\{{name.id}}
            if (value = {{var_prefix}}\{{name.id}}).nil?
              ::raise NilAssertionError.new("\{{@type}}\{{"{{doc_prefix}}".id}}\{{name.id}} cannot be nil")
            else
              value
            end
          end
        \{% end %}
      \{% end %}
    end

    # Defines query getter methods for each of the given arguments.
    macro {{macro_prefix}}getter?(*names, &block)
      \{% if block %}
        \{% if names.size != 1 %}
          \{{ raise "Only one argument can be passed to `getter?` with a block" }}
        \{% end %}

        \{% name = names[0] %}

        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name.var.id}} : \{{name.type}}?

          def {{method_prefix}}\{{name.var.id}}? : \{{name.type}}
            if (value = {{var_prefix}}\{{name.var.id}}).nil?
              {{var_prefix}}\{{name.var.id}} = \{{yield}}
            else
              value
            end
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}?
            if (value = {{var_prefix}}\{{name.id}}).nil?
              {{var_prefix}}\{{name.id}} = \{{yield}}
            else
              value
            end
          end
        \{% end %}
      \{% else %}
        \{% for name in names %}
          \{% if name.is_a?(TypeDeclaration) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.var.id}}? : \{{name.type}}
              {{var_prefix}}\{{name.var.id}}
            end
          \{% elsif name.is_a?(Assign) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.target.id}}?
              {{var_prefix}}\{{name.target.id}}
            end
          \{% else %}
            def {{method_prefix}}\{{name.id}}?
              {{var_prefix}}\{{name.id}}
            end
          \{% end %}
        \{% end %}
      \{% end %}
    end

    # Defines setter methods for each of the given arguments.
    macro {{macro_prefix}}setter(*names)
      \{% for name in names %}
        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name}}

          def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
          end
        \{% elsif name.is_a?(Assign) %}
          {{var_prefix}}\{{name}}

          def {{method_prefix}}\{{name.target.id}}=({{var_prefix}}\{{name.target.id}})
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
          end
        \{% end %}
      \{% end %}
    end

    # Defines property methods for each of the given arguments.
    macro {{macro_prefix}}property(*names, &block)
      \{% if block %}
        \{% if names.size != 1 %}
          \{{ raise "Only one argument can be passed to `property` with a block" }}
        \{% end %}

        \{% name = names[0] %}

        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name.var.id}} : \{{name.type}}?

          def {{method_prefix}}\{{name.var.id}} : \{{name.type}}
            if (value = {{var_prefix}}\{{name.var.id}}).nil?
              {{var_prefix}}\{{name.var.id}} = \{{yield}}
            else
              value
            end
          end

          def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}
            if (value = {{var_prefix}}\{{name.id}}).nil?
              {{var_prefix}}\{{name.id}} = \{{yield}}
            else
              value
            end
          end

          def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
          end
        \{% end %}
      \{% else %}
        \{% for name in names %}
          \{% if name.is_a?(TypeDeclaration) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.var.id}} : \{{name.type}}
              {{var_prefix}}\{{name.var.id}}
            end

            def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
            end
          \{% elsif name.is_a?(Assign) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.target.id}}
              {{var_prefix}}\{{name.target.id}}
            end

            def {{method_prefix}}\{{name.target.id}}=({{var_prefix}}\{{name.target.id}})
            end
          \{% else %}
            def {{method_prefix}}\{{name.id}}
              {{var_prefix}}\{{name.id}}
            end

            def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
            end
          \{% end %}
        \{% end %}
      \{% end %}
    end

    # Defines raise-on-nil property methods for each of the given arguments.
    macro {{macro_prefix}}property!(*names)
      {{macro_prefix}}getter! \{{*names}}

      \{% for name in names %}
        \{% if name.is_a?(TypeDeclaration) %}
          def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
          end
        \{% end %}
      \{% end %}
    end

    # Defines query property methods for each of the given arguments.
    macro {{macro_prefix}}property?(*names, &block)
      \{% if block %}
        \{% if names.size != 1 %}
          \{{ raise "Only one argument can be passed to `property?` with a block" }}
        \{% end %}

        \{% name = names[0] %}

        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name.var.id}} : \{{name.type}}?

          def {{method_prefix}}\{{name.var.id}}? : \{{name.type}}
            if (value = {{var_prefix}}\{{name.var.id}}).nil?
              {{var_prefix}}\{{name.var.id}} = \{{yield}}
            else
              value
            end
          end

          def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}?
            if (value = {{var_prefix}}\{{name.id}}).nil?
              {{var_prefix}}\{{name.id}} = \{{yield}}
            else
              value
            end
          end

          def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
          end
        \{% end %}
      \{% else %}
        \{% for name in names %}
          \{% if name.is_a?(TypeDeclaration) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.var.id}}? : \{{name.type}}
              {{var_prefix}}\{{name.var.id}}
            end

            def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
            end
          \{% elsif name.is_a?(Assign) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.target.id}}?
              {{var_prefix}}\{{name.target.id}}
            end

            def {{method_prefix}}\{{name.target.id}}=({{var_prefix}}\{{name.target.id}})
            end
          \{% else %}
            def {{method_prefix}}\{{name.id}}?
              {{var_prefix}}\{{name.id}}
            end

            def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
            end
          \{% end %}
        \{% end %}
      \{% end %}
    end
  {% end %}

  # Delegate *methods* to *to*.
  #
  # NOTE: Due to current language limitations this is only useful when no captured blocks are involved.
  macro delegate(*methods, to object)
    {% for method in methods %}
      {% if method.id.ends_with?('=') && method.id != "[]=" %}
        def {{method.id}}(arg)
          {{object.id}}.{{method.id}} arg
        end
      {% else %}
        def {{method.id}}(*args, **options)
          {{object.id}}.{{method.id}}(*args, **options)
        end

        {% if method.id != "[]=" %}
          def {{method.id}}(*args, **options)
            {{object.id}}.{{method.id}}(*args, **options) do |*yield_args|
              yield *yield_args
            end
          end
        {% end %}
      {% end %}
    {% end %}
  end

  # Defines a `hash(hasher)` that will append a hash value for the given fields.
  macro def_hash(*fields)
    def hash(hasher)
      {% for field in fields %}
        hasher = {{field.id}}.hash(hasher)
      {% end %}
      hasher
    end
  end

  # Defines an `==` method by comparing the given fields.
  #
  # The generated `==` method has a `self` restriction.
  macro def_equals(*fields)
    def ==(other : self) : Bool
      {% if @type.class? %}
        return true if same?(other)
      {% end %}
      {% for field in fields %}
        return false unless {{field.id}} == other.{{field.id}}
      {% end %}
      true
    end
  end

  # Defines `hash` and `==` method from the given fields.
  #
  # The generated `==` method has a `self` restriction.
  macro def_equals_and_hash(*fields)
    def_equals {{*fields}}
    def_hash {{*fields}}
  end

  # Forwards missing methods to *delegate*.
  macro forward_missing_to(delegate)
    macro method_missing(call)
      {{delegate}}.\{{call}}
    end
  end

  # Defines a `clone` method that returns a copy of this object with all instance variables cloned.
  macro def_clone
    # Returns a copy of `self` with all instance variables cloned.
    def clone
      \{% if @type < Reference && !@type.instance_vars.map(&.type).all? { |t| t == ::Bool || t == ::Char || t == ::Symbol || t == ::String || t < ::Number::Primitive } %}
        exec_recursive_clone do |hash|
          clone = \{{@type}}.allocate
          hash[object_id] = clone.object_id
          clone.initialize_copy(self)
          GC.add_finalizer(clone) if clone.responds_to?(:finalize)
          clone
        end
      \{% else %}
        clone = \{{@type}}.allocate
        clone.initialize_copy(self)
        GC.add_finalizer(clone) if clone.responds_to?(:finalize)
        clone
      \{% end %}
    end

    protected def initialize_copy(other)
      \{% for ivar in @type.instance_vars %}
        @\{{ivar.id}} = other.@\{{ivar.id}}.clone
      \{% end %}
    end
  end

  protected def self.set_crystal_type_id(ptr)
    ptr.as(Pointer(typeof(crystal_instance_type_id))).value = crystal_instance_type_id
    ptr
  end
end
