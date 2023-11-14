# Buffer with a cursor (Buwic)

A Luau wrapper for the built-in `buffer` type.

To simplify the implementation and make it as close to baremetal as is possible for Luau, the built-in `buffer` type doesn't provide a cursor. This means that using it for sequential reads and writes requires you to keep track of where you're reading and writing from, as well as the size of the buffer so that you don't overflow.

This module provides a wrapper around the built-in library to give it some new functionality:

- A cursor to keep track of where you're reading and writing from and to
- Dynamic resizing as you write
- Functionality to grow or shrink it

This module **does not** provide the following functionality:

- Base conversion functions like Base64, Base91, etc.
- Bit-level writes

That functionality dramatically slows complicates this module and slows it down, so it's not provided.

This library aims to be as fast as possible, but there is some overhead associated with functions and tables that is not present for pure VM types. As a result, it is quite a bit slower than a raw implementation.

The API is below:

## API

TODO: API

- read/write `u8`, `u16`, `u24`, `u32`
- read/write `i8`, `i16`, `i24`, `i32`
- read/write `f32`, `f64`

- read/write length prefixed string
- read/write 'raw string'
- read/write buffer

- Roblox stuff