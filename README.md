# crystal-std-lite

Here is my personal record of learning [Crystal](https://crystal-lang.org) standard library.

It's a subset of the official standard library. So, if the code can be compiled with this library, then it should also be able to compile with the official standard library. The reverse is not.

**NOTE**: Much of the code comes directly from [official repository](https://github.com/crystal-lang/crystal) and copyright belongs to all authors and contributors.

## Installation

Clone or download it and add it to `CRYSTAL_PATH` environment variable.

**NOTE**: It should be placed between `lib` and `path-to-official-std-lib`.

## Usage

Just use `crystal` and `shards` in the normal way.

**NOTE**: You can play around with this library, but use it sparingly for developing products.

## Development

* Only the standard library is involved, not the compiler part.
* Only generic code is involved, not platform-dependent underlying code.
* Only part of the APIs are implemented, not all.
* Prefer simple implementations.
* Prefer mark types, because types are good documentation and can reduce bugs.

## Contributing

1. Fork it (<https://github.com/erdian718/crystal-std-lite/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Erdian718](https://github.com/erdian718) - creator and maintainer
