# Roblox Data Type Specification

Every Roblox data type has a method for reading and writing it. The format for each data type is listed below for convenience, as it is not defined by the `buffer` library.

All numbers follow the format specified by the `buffer` library.

## Table Of Contents
- [Axes](#axes)
- [BrickColor](#brickcolor)
- [CFrame](#cframe)
- [Color3](#color3)
- [Color3uint8](#color3uint8)
- [ColorSequence](#colorsequence)
- [DateTime](#datetime)
- [EnumItem](#enumitem)
- [Faces](#faces)
- [Font](#font)
- [NumberRange](#numberrange)
- [NumberSequence](#numbersequence)
- [PhysicalProperties](#physicalproperties)
- [Ray](#ray)
- [Rect](#rect)
- [Region3](#region3)
- [UDim](#udim)
- [UDim2](#udim2)
- [Vector2](#vector2)
- [Vector2int16](#vector2int16)
- [Vector3](#vector3)
- [Vector3int16](#vector3int16)

## Axes

An [`Axes`][Axes_DT] is written as a single `u8`. This value is a bitfield where the lower 3 bits of it represent what axes are enabled on the `Axes`. From most-significant to least-significant, the 3 bits represent the `Z`, `Y`, and `X` fields on the `Axes`.

## BrickColor

A [`BrickColor`][BrickColor_DT] is written as a single `u16`. This value represents the `Number` field of the color.

## CFrame

A [`CFrame`][CFrame_DT] is written in three parts. First, three `f32` values are written representing the `X`, `Y`, and `Z` components of the `CFrame`'s position. Then, an ID is written representing the rotation of the CFrame. This ID has two different meanings:

### Orthonormalized CFrame, Axis-Aligned

If the `CFrame` is [orthonormal][Orthogonality_Wiki] and also aligned to the axes, this ID is a compression of the rotation matrix:

- The lowest three bits represent the Y-column/UpVector of the `CFrame`
- The next 3 bits represent the X-column/RightVector of the `CFrame`

These values are both numbers for a variant of the `NormalId` enum, which can be turned into a unit vector using `Vector3.fromNormalId`. The Z-column/LookVector is not written but may be derived by taking the cross product between the X-column and Y-column.

### Orthonormalized CFrame, not Axis-Aligned

If the `CFrame` is orthonormal but not aligned to the axes, the ID is instead `0x40`. In this case, the rotation matrix is written as three `f32` values representing the axis-angle representation of the rotation as a `Vector3`, where the magnitude is the angle and the unit form is the axis.

### Non-Orthonormalized CFrame

For performance, non-orthonormalized CFrames are not supported. They can instead be manually written as twelve `f32` values.

## Color3

A [`Color3`][Color3_DT] is written as three `f32` values. These values represent the `R`, `G`, and `B` fields of the color, in that order.

## Color3uint8

A [`Color3`][Color3_DT] written as three `u8`s instead of three `f32`s to save space. These three values represent the `R`, `G`, and `B` fields of the color, in that order.

When serializing a `Color3` as a `Color3uint8`, the value is made via `math.floor(c * 255)` where `c` is the float-version of the component.

## ColorSequence

A [`ColorSequence`][ColorSequence_DT] is written in two parts. First is a `u32` indicating how many [`ColorSequenceKeypoint`][ColorSequenceKeypoint_DT]s the sequence has. Each keypoint is written in sequence after that, meaning this data type is dynamically sized.

Each `ColorSequenceKeypoint` is written as four `f32`s, representing the `Time`, `Value.R`, `Value.G`, and `Value.B` fields for that keypoint in order.

## DateTime

A [`DateTime`][DateTime_DT] is written as an `f64` representing the time in milliseconds since the Unix epoch. This is analoglous to just directly writing the `UnixTimestampMillis` field as an `f64`.

## EnumItem

An [`EnumItem`][EnumItem_DT] is written in two parts. The first is `u32` representing the `Value` field of the `EnumItem`.

The second is the name of the [`Enum`][Enum_DT] that the `EnumItem` is a part of. This value is written first as a `u16` indicating how long the name of the `Enum` is, followed by the literal bytes of the `Enum`'s name.

## Faces

A [`Faces`][Faces_DT] is written as a single `u8`. This value is a bitfield where the lower 6 bits of it represent what faces are enabled on the `Faces`. From most-significant to least-significant, the 6 bits represent the `Top`, `Left`, `Front`, `Bottom`, `Right`, and `Back` fields on the `Faces`.

## Font

A [`Font`][Font_DT] is written in three parts. The first is the `Style` of the font, written as a `u8` representing the underlying value of the `FontStyle` enum.

The second is the `Weight` of the font, written as a `u16` that represents the value of the `FontWeight` enum.

The third is the `Family` of the font. This value is first written as a `u16` indicating how long the `Family`'s URI is followed by the literal bytes of the `Family` field.

## NumberRange

A [`NumberRange`][NumberRange_DT] is written as two `f32` values representing the `Min` and `Max` fields of the `NumberRange` in that order.

## NumberSequence

A [`NumberSequence`][NumberSequence_DT] is written in two parts. First is a `u32` indicating how many [`NumberSequenceKeypoint`][NumberSequenceKeypoint_DT]s the sequence has. Each keypoint is written in sequence after that, meaning this data type is dynamically sized.

Each `NumberSequenceKeypoint` is written as three `f32`s, representing the `Time`, `Value`, and `Envelope` fields for that keypoint in order.

## PhysicalProperties

A [`PhysicalProperties`][PhysicalProperties_DT] is written as five `f32` values representing the components of the data type. These values are written in the order `Density`, `Friction`, `Elasticity`, `FrictionWeight`, and `ElasticityWeight`.

This data type is stored naively without accounting for the possibility of a `PhysicalProperties` being directly created from a [`Material`][Material_E] enum variant. This is for performance.

## Ray

A [`Ray`][Ray_DT] is written as six `f32` values representing the components of the ray's `Origin` and `Direction`. Specificially, the values are written in the following order: `Origin.X`, `Origin.Y`, `Origin.Z`, `Direction.X`, `Direction.Y`, and `Direction.Z`.

## Rect

A [`Rect`][Rect_DT] is written as four `f32` values representing the components of the `Rect`'s `Min` and `Max`. Specificially, the values are written in the following order: `Min.X`, `Min.Y`, `Max.X`, `Max.Y`.

## Region3

[`Region3`][Region3_DT] values are not supported by Buwic due to the inaccuracy it requires. There is no way to get the Min and Max values of a `Region3` with full accuracy and thus it is dangerous to encourage people to write them directly into a Buwic.

## UDim

A [`UDim`][UDim_DT] is written as two parts: an `f32` representing the `Scale`, and an `i32` representing the `Offset`. These values are written in the order they're listed above.

## UDim2

A [`UDim2`][UDim2_DT] is written as four parts representing the components of the `X` and `Y` fields. These are:
- An `f32` for `X.Scale`
- An `i32` for `X.Offset`
- An `f32` for `Y.Scale`
- An `i32` for `Y.Offset`

## Vector2

A [`Vector2`][Vector2_DT] is written as two `f32` values representing the `X` and `Y` fields of the vector, in that order.

## Vector2int16

A [`Vector2int16`][Vector2int16_DT] is written as two `i16` values representing the `X` and `Y` fields of the vector, in that order.

## Vector3

A [`Vector3`][Vector3_DT] is written as three `f32` values representing the `X`, `Y`, and `Z` fields of the vector, in that order.

## Vector3int16

A [`Vector3int16`][Vector3int16_DT] is written as three `i16` values representing the `X`, `Y`, and `Z` fields of the vector, in that order.

<!-- Link repository -->

[Axes_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Axes
[BrickColor_DT]: https://create.roblox.com/docs/reference/engine/datatypes/BrickColor
[CFrame_DT]: https://create.roblox.com/docs/reference/engine/datatypes/CFrame
[Color3_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Color3
[ColorSequence_DT]: https://create.roblox.com/docs/reference/engine/datatypes/ColorSequence
[ColorSequenceKeypoint_DT]: https://create.roblox.com/docs/reference/engine/datatypes/ColorSequenceKeypoint
[DateTime_DT]: https://create.roblox.com/docs/reference/engine/datatypes/DateTime
[Enum_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Enum
[EnumItem_DT]: https://create.roblox.com/docs/reference/engine/datatypes/EnumItem
[Faces_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Faces
[Font_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Font
[NumberRange_DT]: https://create.roblox.com/docs/reference/engine/datatypes/NumberRange
[NumberSequence_DT]: https://create.roblox.com/docs/reference/engine/datatypes/NumberSequence
[NumberSequenceKeypoint_DT]: https://create.roblox.com/docs/reference/engine/datatypes/NumberSequenceKeypoint
[PhysicalProperties_DT]: https://create.roblox.com/docs/reference/engine/datatypes/PhysicalProperties
[Ray_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Ray
[Rect_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Rect
[Region3_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Region3
[UDim_DT]: https://create.roblox.com/docs/reference/engine/datatypes/UDim
[UDim2_DT]: https://create.roblox.com/docs/reference/engine/datatypes/UDim2
[Vector2_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Vector2
[Vector2int16_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Vector2int16
[Vector3_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Vector3
[Vector3int16_DT]: https://create.roblox.com/docs/reference/engine/datatypes/Vector3int16

[Material_E]: https://create.roblox.com/docs/reference/engine/enums/Material

[Orthogonality_Wiki]: https://en.wikipedia.org/wiki/Orthogonality