# Buffer with a cursor (Buwic)

A Luau wrapper for the built-in `buffer` type. Made for Roblox, but most of it should be usable outside of Luau as well.

To simplify the implementation and make it as close to baremetal as is possible for Luau, the built-in `buffer` type doesn't provide a cursor. This means that using it for sequential reads and writes requires you to keep track of where you're reading and writing from, as well as the size of the buffer so that you don't overflow.

This module provides a wrapper around the built-in library to give it some new functionality:

- A cursor to keep track of where you're reading and writing from and to
- Dynamic resizing as you write
- Functionality to grow or shrink it

This module **does not** provide the following functionality:

- Base conversion functions like Base64, Base91, etc.
- Bit-level writes

That functionality dramatically complicates this module and slows it down, so it's not provided.

This library aims to be as fast as possible, but there is some overhead associated with functions and tables that can't be avoided. Using a Ryzen 5500U, this module takes roughly twice as long per operation without native codegen. With native codegen, that number is 1.6 times as long instead of 2. This is still *very* fast, and odds are against you needing something faster. If you do though, use the raw `buffer` library.

The API is below:

## API

The API for this module can be roughly divided into three categories: write methods, read methods, and everything else. An API for reading and writing is exposed for the following types:
- `u8`, `u16`, `u24`, `u32`
- `i8`, `i16`, `i24`, `i32`
- `f32`, `f64`
- `bool`, bitfields
- Raw byte sequences, as both a `string` and a `buffer`
- Strings prefixed with their length
<!--TODO Bitfields  -->

Additionally, the following Roblox data types are included:
- `CFrame`, `Vector3`, `Vector2`, `Vector2int16`, `Vector3int16`
- `UDim`, `UDim2`, `Rect`, `Ray`
- `BrickColor`, `Color3`, `Color3` as a `u24`
- `NumberRange`, `NumberSequence`, `ColorSequence`
- `Enum`
- `DateTime`, `Font`, `PhysicalProperties`
- `Axes`, `Faces`

The format used by each Roblox data type is documented [**here**](roblox_spec.md) for convenience.

Beyond the basic read and write functions, there's several methods provided for basic manipulation of a Buwic. They are:
- `Buwic.new`, `Buwic.fromString`, `Buwic.fromBuffer`
- `Buwic.isA`
- `toString`, `toBuffer`, `getRawBuffer`
- `getCursor`, `setCursor`
- `capacity`, `reserve`, `shrink`

All of these functions are documented briefly below. For more detailed documentation, see [blank]

### Constructors

> `Buwic.new(capacity: number?): Buwic`

Creates a new `Buwic`. If `capacity` is provided, it is the initial size in bytes that the `Buwic` can hold without resizing. Otherwise, the `Buwic` starts able to hold `0` bytes.

This function errors if `capacity` is less than 0, not a real number, or greater than the maximum size of a `buffer`.