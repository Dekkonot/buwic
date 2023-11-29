--!strict
--!optimize 2

local Buwic = {}
Buwic.__index = Buwic

export type Buwic = typeof(setmetatable(
	{} :: {
		_buffer: buffer,
		_cursor: number,
	},
	Buwic
))

--- A map of FontStyle variants to their `Value` field
local NUMBER_TO_FONTSTYLE = {}
--- A map of FontWeight variants to their `Value` field
local NUMBER_TO_FONTWEIGHT = {}

for _, item: Enum.FontStyle in Enum.FontStyle:GetEnumItems() do
	NUMBER_TO_FONTSTYLE[item.Value] = item
end
for _, item: Enum.FontWeight in Enum.FontWeight:GetEnumItems() do
	NUMBER_TO_FONTWEIGHT[item.Value] = item
end

--- Convenience function for dynamically resizing the buffer.
--- Designed to be inlined by the compiler.
local function resizeIfNeeded(buwic: Buwic, more: number)
	local len = buffer.len(buwic._buffer)
	if buwic._cursor + more > len then
		-- We could resize to the next power of two
		-- but it's unclear if that's what people want.
		-- local new = buffer.create(2 ^ (math.floor(math.log(len + more, 2)) + 1))
		local new = buffer.create(len + more)
		-- print(`resizing to {buffer.len(new)} from {len}`)
		buffer.copy(new, 0, buwic._buffer, 0, len)
		buwic._buffer = new
	end
end

--- Writes a u24 to the provided `Buwic`.
--- This is separate so that it can be inlined in both `Buwic.writeu24`
--- and `Buwic.writei24`.
local function writeu24(buwic: Buwic, n: number)
	resizeIfNeeded(buwic, 3)
	buffer.writeu8(buwic._buffer, buwic._cursor, bit32.band(n, 0xFF))
	buffer.writeu16(buwic._buffer, buwic._cursor + 1, bit32.rshift(n, 8))
	buwic._cursor += 3
end

--- Reads a u24 from the provided `Buwic`.
--- This is separate so that it can be inlined in both `Buwic.readu24`
--- and `Buwic.readi24`.
local function readu24(buwic: Buwic): number
	local n = buffer.readu16(buwic._buffer, buwic._cursor)
	buwic._cursor += 3
	return bit32.lshift(buffer.readu8(buwic._buffer, buwic._cursor - 1), 16) + n
end

--- Constructs a new `Buwic` with the provided capacity, or 0 if none is
--- provided.
function Buwic.new(capacity: number?): Buwic
	return setmetatable({
		_buffer = buffer.create(capacity or 0),
		-- This is a load bearing field. I assume it's a cache thing but I don't know.
		_len = 0,
		_cursor = 0,
	}, Buwic)
end

--- Constructs a new `Buwic` from the provided string.
function Buwic.fromString(str: string): Buwic
	local self = Buwic.new(#str)
	buffer.writestring(self._buffer, 0, str)
	return self
end

--- Constructs a new `Buwic` from the provided buffer.
---
--- This function copies the contents of the buffer and does not store
--- references to it, so it may be used freely after this function.
function Buwic.fromBuffer(buff: buffer): Buwic
	local self = Buwic.new(buffer.len(buff))
	buffer.copy(self._buffer, 0, buff, buffer.len(buff))
	return self
end

-- Accesor methods --

--- Converts the `Buwic` to a string. This string will not be valid UTF-8.
function Buwic.toString(self: Buwic): string
	return buffer.readstring(self._buffer, 0, buffer.len(self._buffer))
end

--- Returns how many bytes the `Buwic` is currently capable of storing.
--- The `Buwic` will still resize from this point.
function Buwic.capacity(self: Buwic): number
	return buffer.len(self._buffer)
end

--- Returns the internal cursor used by the `Buwic`. This cursor is 0 based,
--- and is in bytes.
function Buwic.getCursor(self: Buwic): number
	return self._cursor
end

-- Modifying methods --

--- Sets the internal cursor used by the `Buwic`. This cursor is 0 based,
--- and is in bytes.
---
--- To reset the cursor, this method should be used to set it to `0`.
function Buwic.setCursor(self: Buwic, location: number)
	self._cursor = location
end

--- Reserves `more` bytes in the internal buffer, triggering a resize.
--- This can be useful when performing many writes sequentially if the size is
--- known beforehand to reduce the number of reallocations done.
function Buwic.reserve(self: Buwic, more: number)
	local len = buffer.len(self._buffer)
	local new = buffer.create(len + more)
	-- print(`resizing to {buffer.len(new)} from {len}`)
	buffer.copy(new, 0, self._buffer, 0, len)
	self._buffer = new
end

--- Shrinks the internal capacity by `less` bytes, triggering a resize.
--- This method effectively truncates the `Buwic`, chopping `less` bytes off of
--- the end.
---
--- If the cursor would be outside the new capacity, it is placed at the end
--- of the `Buwic`. Otherwise it's left where it was.
function Buwic.shrink(self: Buwic, less: number)
	local len = buffer.len(self._buffer)
	local new = buffer.create(math.max(len - less, 0))
	-- print(`shrinking to {buffer.len(new)} from {len}`)
	buffer.copy(new, 0, self._buffer, 0, len - less)
	if self._cursor > buffer.len(new) then
		self._cursor = buffer.len(new)
	end
	self._buffer = new
end

-- Basic Writers --

--- Writes an unsigned 8-bit integer (`u8`) to the `Buwic`.
---
--- May error if `n` is outside the range `[0, 255]`.
function Buwic.writeu8(self: Buwic, n: number)
	resizeIfNeeded(self, 1)
	buffer.writeu8(self._buffer, self._cursor, n)
	self._cursor += 1
end

--- Writes a signed 8-bit integer (`i8`) to the `Buwic`.
---
--- May error if `n` is outside the range `[-128, 127]`.
function Buwic.writei8(self: Buwic, n: number)
	resizeIfNeeded(self, 1)
	buffer.writei8(self._buffer, self._cursor, n)
	self._cursor += 1
end

--- Writes an unsigned 16-bit integer (`u16`) to the `Buwic`.
---
--- May error if `n` is outside the range `[0, 65535]`.
function Buwic.writeu16(self: Buwic, n: number)
	resizeIfNeeded(self, 2)
	buffer.writeu16(self._buffer, self._cursor, n)
	self._cursor += 2
end

--- Writes a signed 16-bit integer (`i16`) to the `Buwic`.
---
--- May error if `n` is outside the range `[-32768, 32767]`.
function Buwic.writei16(self: Buwic, n: number)
	resizeIfNeeded(self, 2)
	buffer.writei16(self._buffer, self._cursor, n)
	self._cursor += 2
end

--- Writes an unsigned 24-bit integer (`u24`) to the `Buwic`.
---
--- May error if `n` is outside the range `[0, 16777215]`.
function Buwic.writeu24(self: Buwic, n: number)
	writeu24(self, n)
end

--- Writes a signed 24-bit integer (`i24`) to the `Buwic`.
---
--- May error if `n` is outside the range `[-8388608, 8388607]`.
function Buwic.writei24(self: Buwic, n: number)
	writeu24(self, n % 0x1000_000)
end

--- Writes an unsigned 32-bit integer (`u32`) to the `Buwic`.
---
--- May error if `n` is outside the range `[0, 4294967295]`.
function Buwic.writeu32(self: Buwic, n: number)
	resizeIfNeeded(self, 4)
	buffer.writeu32(self._buffer, self._cursor, n)
	self._cursor += 4
end

--- Writes a signed 32-bit integer (`i32`) to the `Buwic`.
---
--- May error if `n` is outside the range `[-2147483648, 2147483647]`.
function Buwic.writei32(self: Buwic, n: number)
	resizeIfNeeded(self, 4)
	buffer.writei32(self._buffer, self._cursor, n)
	self._cursor += 4
end

--- Writes a 32-bit floating-point number (`f32`) to the `Buwic`.
function Buwic.writef32(self: Buwic, n: number)
	resizeIfNeeded(self, 4)
	buffer.writef32(self._buffer, self._cursor, n)
	self._cursor += 4
end

--- Writes a 64-bit floating-point number (`f64`) to the `Buwic`.
function Buwic.writef64(self: Buwic, n: number)
	resizeIfNeeded(self, 8)
	buffer.writef64(self._buffer, self._cursor, n)
	self._cursor += 8
end

--- Writes a string as sequence of bytes to the `Buwic`. If `len` is provided,
--- only `len` bytes will be written. Otherwise, the entirety of `str` will be
--- written to the `Buwic`.
---
--- This method does not prefix the string with a length. To write a string
--- like that, see `writeString`.
function Buwic.writeRawString(self: Buwic, str: string, len: number?)
	resizeIfNeeded(self, len or #str)
	buffer.writestring(self._buffer, self._cursor, str, len)
	self._cursor += len or #str
end

--- Writes a string to the `Buwic`. If `len` is provided, only `len` bytes
--- will be written. Otherwise, the entirety of `str` will be written to
--- the `Buwic`.
---
--- This method prefixes the string with a length. To write a string
--- without that, see `writeRawString`.
function Buwic.writeString(self: Buwic, str: string, len: number?)
	resizeIfNeeded(self, (len or #str) + 4)
	buffer.writeu32(self._buffer, self._cursor, len or #str)
	buffer.writestring(self._buffer, self._cursor + 4, str, len)
	self._cursor += #str + 4
end

--- Writes a buffer to the `Buwic`. If `len` is provided, only `len`
--- bytes from the buffer will be copied. Otherwise, the entirety buffer will
--- be copied into the `Buwic`.
function Buwic.writeBuffer(self: Buwic, buff: buffer, len: number?)
	resizeIfNeeded(self, len or buffer.len(buff))
	buffer.copy(self._buffer, self._cursor, buff, 0, len)
	self._cursor += len or buffer.len(buff)
end

-- Basic Readers --

--- Reads an unsigned 8-bit integer (`u8`) from the `Buwic`.
function Buwic.readu8(self: Buwic): number
	local n = buffer.readu8(self._buffer, self._cursor)
	self._cursor += 1
	return n
end

--- Reads a signed 8-bit integer (`i8`) from the `Buwic`.
function Buwic.readi8(self: Buwic): number
	local n = buffer.readi8(self._buffer, self._cursor)
	self._cursor += 1
	return n
end

--- Reads an unsigned 16-bit integer (`u16`) from the `Buwic`.
function Buwic.readu16(self: Buwic): number
	local n = buffer.readu16(self._buffer, self._cursor)
	self._cursor += 2
	return n
end

--- Reads a signed 16-bit integer (`i16`) from the `Buwic`.
function Buwic.readi16(self: Buwic): number
	local n = buffer.readi16(self._buffer, self._cursor)
	self._cursor += 2
	return n
end

--- Reads an unsigned 24-bit integer (`u24`) from the `Buwic`.
function Buwic.readu24(self: Buwic): number
	return readu24(self)
end

--- Reads a signed 24-bit integer (`i24`) from the `Buwic`.
function Buwic.readi24(self: Buwic): number
	local n = readu24(self)
	return if n >= 0x800000 then n - 0x1000000 else n
end

--- Reads an unsigned 32-bit integer (`u32`) from the `Buwic`.
function Buwic.readu32(self: Buwic): number
	local n = buffer.readu32(self._buffer, self._cursor)
	self._cursor += 4
	return n
end

--- Reads a signed 32-bit integer (`i32`) from the `Buwic`.
function Buwic.readi32(self: Buwic): number
	local n = buffer.readi32(self._buffer, self._cursor)
	self._cursor += 4
	return n
end

--- Reads a 32-bit floating-point number (`f32`) from the `Buwic`.
function Buwic.readf32(self: Buwic): number
	local n = buffer.readf32(self._buffer, self._cursor)
	self._cursor += 4
	return n
end

--- Reads a 64-bit floating-point number (`f64`) from the `Buwic`.
function Buwic.readf64(self: Buwic): number
	local n = buffer.readf64(self._buffer, self._cursor)
	self._cursor += 8
	return n
end

--- Reads a sequence of `len` bytes from the `Buwic` into a string.
function Buwic.readRawString(self: Buwic, len: number): string
	local str = buffer.readstring(self._buffer, self._cursor, len)
	self._cursor += len
	return str
end

--- Reads a string from the `Buwic`.
function Buwic.readString(self: Buwic): string
	local len = buffer.readu32(self._buffer, self._cursor)
	local str = buffer.readstring(self._buffer, self._cursor + 4, len)
	self._cursor += len + 4
	return str
end

--- Reads `len` bytes from the `Buwic` and places them into a buffer.
function Buwic.readBuffer(self: Buwic, len: number): buffer
	local out = buffer.create(len)
	buffer.copy(out, 0, self._buffer, self._cursor, len)
	self._cursor += len
	return out
end

-- TODO: function for reading and writing vectors

-- Roblox specific writers --

--- Writes an `Axes` to the `Buwic`.
function Buwic.writeAxes(self: Buwic, axes: Axes)
	resizeIfNeeded(self, 1)
	buffer.writeu8(
		self._buffer,
		self._cursor,
		(axes.Z and 0b100 or 0b000) + (axes.Y and 0b010 or 0b000) + (axes.X and 0b001 or 0b000)
	)
	self._cursor += 1
end

--- Writes a `BrickColor` to the `Buwic`.
function Buwic.writeBrickColor(self: Buwic, color: BrickColor)
	resizeIfNeeded(self, 2)
	buffer.writeu16(self._buffer, self._cursor, color.Number)
	self._cursor += 2
end

--- Writes a `CFrame` to the `Buwic`.
function Buwic.writeCFrame(self: Buwic, cframe: CFrame)
	resizeIfNeeded(self, 12 * 3)
	local b, c = self._buffer, self._cursor
	--stylua: ignore
	local x, y, z,
		r00, r01, r02,
		r10, r11, r12,
		r20, r21, r22 = cframe:GetComponents()
	buffer.writef32(b, c, x)
	buffer.writef32(b, c + 4, y)
	buffer.writef32(b, c + 8, z)
	buffer.writef32(b, c + 12, r00)
	buffer.writef32(b, c + 16, r01)
	buffer.writef32(b, c + 20, r02)
	buffer.writef32(b, c + 24, r10)
	buffer.writef32(b, c + 28, r11)
	buffer.writef32(b, c + 32, r12)
	buffer.writef32(b, c + 36, r20)
	buffer.writef32(b, c + 40, r21)
	buffer.writef32(b, c + 44, r22)
	self._cursor += 12 * 3
end

--- Writes a `Color3` to the `Buwic`.
function Buwic.writeColor3(self: Buwic, color: Color3)
	resizeIfNeeded(self, 12)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, color.R)
	buffer.writef32(b, c + 4, color.G)
	buffer.writef32(b, c + 8, color.B)
	self._cursor += 12
end

--- Writes a `Color3` to the `Buwic` but with `u8` components instead of
--- floats. Colors written with this method are 1/4 the size of those written
--- with `writeColor3` but components are truncuated to be between `0` and `1`.
function Buwic.writeColor3uint8(self: Buwic, color: Color3)
	resizeIfNeeded(self, 3)
	local b, c = self._buffer, self._cursor
	buffer.writeu8(b, c, math.floor(color.R * 255))
	buffer.writeu8(b, c + 4, math.floor(color.G * 255))
	buffer.writeu8(b, c + 8, math.floor(color.B * 255))
	self._cursor += 3
end

--- Writes a `ColorSequence` to the `Buwic`. The number of bytes this method
--- writes is determined by the number of keypoints in the `ColorSequence`.
function Buwic.writeColorSequence(self: Buwic, sequence: ColorSequence)
	local keypoints = sequence.Keypoints
	resizeIfNeeded(self, 4 + #keypoints * 16)
	local b, c = self._buffer, self._cursor
	buffer.writeu32(b, c, #keypoints)
	for i, keypoint in keypoints do
		buffer.writef32(b, c + 4 + 16 * (i - 1), keypoint.Time)
		buffer.writef32(b, c + 8 + 16 * (i - 1), keypoint.Value.R)
		buffer.writef32(b, c + 12 + 16 * (i - 1), keypoint.Value.G)
		buffer.writef32(b, c + 16 + 16 * (i - 1), keypoint.Value.B)
	end
	self._cursor += (4 + #keypoints * 16)
end

--- Writes a `DateTime` to the `Buwic`.  This is equivalent to writing
--- the `UnixTimestampMillis` of the `DateTime` as an `f64`.
function Buwic.writeDateTime(self: Buwic, date: DateTime)
	resizeIfNeeded(self, 8)
	buffer.writef64(self._buffer, self._cursor, date.UnixTimestampMillis)
	self._cursor += 8
end

--- Writes an `EnumItem` to the `Buwic`. This method writes the name of
--- `enum`'s type as well as the value of `enum`, so it can be read without
--- prior knowledge. However, this increases the overall written size
--- dynamically.
function Buwic.writeEnum(self: Buwic, enum: EnumItem)
	local enumType = tostring(enum.EnumType)
	resizeIfNeeded(self, #enumType + 6) -- 2 from prefix, 4 from enum value
	local b, c = self._buffer, self._cursor
	buffer.writeu32(b, c, enum.Value)
	-- I feel confidant Roblox will never make an enum with more than 16,000
	-- characters in its name.
	buffer.writeu16(b, c + 4, #enumType)
	buffer.writestring(b, c + 6, enumType)
end

--- Writes a `Faces` to the `Buwic`.
function Buwic.writeFaces(self: Buwic, faces: Faces)
	resizeIfNeeded(self, 1)
	-- Top, Left, Front, Bottom, Right, Back
	buffer.writeu8(
		self._buffer,
		self._cursor,
		(faces.Top and 0b100_000 or 0)
			+ (faces.Left and 0b010_000 or 0)
			+ (faces.Front and 0b001_000 or 0)
			+ (faces.Bottom and 0b000_100 or 0)
			+ (faces.Right and 0b000_010 or 0)
			+ (faces.Back and 0b000_001 or 0)
	)
	self._cursor += 1
end

--- Writes a `Font` to the `Buwic`. The number of bytes this method writes
--- is determined by the length of the font's `Family` field.
function Buwic.writeFont(self: Buwic, font: Font)
	local family = font.Family
	resizeIfNeeded(self, 6 + #family)
	local b, c = self._buffer, self._cursor

	buffer.writeu8(b, c, font.Style.Value)
	buffer.writeu16(b, c + 1, font.Weight.Value)
	buffer.writeu16(b, c + 3, #family)
	buffer.writestring(b, c + 5, family)
	self._cursor += 6 + #family
end

--- Writes a `NumberRange` to the `Buwic`.
function Buwic.writeNumberRange(self: Buwic, range: NumberRange)
	resizeIfNeeded(self, 8)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, range.Min)
	buffer.writef32(b, c + 4, range.Max)
	self._cursor += 8
end

--- Writes a `NumberSequence` to the `Buwic`. The number of bytes this method
--- writes is determined by the number of keypoints in the `NumberSequence`.
function Buwic.writeNumberSequence(self: Buwic, sequence: NumberSequence)
	local keypoints = sequence.Keypoints
	resizeIfNeeded(self, 4 + #keypoints * 12)
	local b, c = self._buffer, self._cursor
	buffer.writeu32(b, c, #keypoints)
	for i, keypoint in keypoints do
		buffer.writef32(b, c + 4 + 12 * (i - 1), keypoint.Time)
		buffer.writef32(b, c + 8 + 12 * (i - 1), keypoint.Value)
		buffer.writef32(b, c + 12 + 12 * (i - 1), keypoint.Envelope)
	end
	self._cursor += (4 + #keypoints * 12)
end

--- Writes a `PhysicalProperties` to the `Buwic`.
function Buwic.writePhysicalProperties(self: Buwic, physicalProperties: PhysicalProperties)
	resizeIfNeeded(self, 20)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, physicalProperties.Density)
	buffer.writef32(b, c + 4, physicalProperties.Friction)
	buffer.writef32(b, c + 8, physicalProperties.Elasticity)
	buffer.writef32(b, c + 12, physicalProperties.FrictionWeight)
	buffer.writef32(b, c + 16, physicalProperties.ElasticityWeight)
	self._cursor += 20
end

--- Writes a `Ray` to the `Buwic`.
function Buwic.writeRay(self: Buwic, ray: Ray)
	resizeIfNeeded(self, 24)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, ray.Origin.X)
	buffer.writef32(b, c + 4, ray.Origin.Y)
	buffer.writef32(b, c + 8, ray.Origin.Z)
	buffer.writef32(b, c + 12, ray.Direction.X)
	buffer.writef32(b, c + 16, ray.Direction.Y)
	buffer.writef32(b, c + 20, ray.Direction.Z)
	self._cursor += 24
end

--- Writes a `Rect` to the `Buwic`.
function Buwic.writeRect(self: Buwic, rect: Rect)
	resizeIfNeeded(self, 16)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, rect.Min.X)
	buffer.writef32(b, c + 4, rect.Min.Y)
	buffer.writef32(b, c + 8, rect.Max.X)
	buffer.writef32(b, c + 12, rect.Max.Y)
	self._cursor += 16
end

--- Writes a `UDim` to the `Buwic`.
function Buwic.writeUDim(self: Buwic, udim: UDim)
	resizeIfNeeded(self, 8)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, udim.Scale)
	buffer.writei32(b, c + 4, udim.Offset)
	self._cursor += 8
end

--- Writes a `UDim2` to the `Buwic`.
function Buwic.writeUDim2(self: Buwic, udim2: UDim2)
	resizeIfNeeded(self, 16)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, udim2.X.Scale)
	buffer.writei32(b, c + 4, udim2.X.Offset)
	buffer.writef32(b, c + 8, udim2.Y.Scale)
	buffer.writei32(b, c + 12, udim2.Y.Offset)
	self._cursor += 16
end

--- Writes a `Vector2` to the `Buwic`.
function Buwic.writeVector2(self: Buwic, vector: Vector2)
	resizeIfNeeded(self, 8)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, vector.X)
	buffer.writef32(b, c + 4, vector.Y)
	self._cursor += 8
end

--- Writes a `Vector2int16` to the `Buwic`.
function Buwic.writeVector2int16(self: Buwic, vector: Vector2int16)
	resizeIfNeeded(self, 4)
	local b, c = self._buffer, self._cursor
	buffer.writei16(b, c, vector.X)
	buffer.writei16(b, c + 2, vector.Y)
	self._cursor += 4
end

--- Writes a `Vector3` to the `Buwic`.
function Buwic.writeVector3(self: Buwic, vector: Vector3)
	resizeIfNeeded(self, 12)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, vector.X)
	buffer.writef32(b, c + 4, vector.Y)
	buffer.writef32(b, c + 8, vector.Z)
	self._cursor += 12
end

--- Writes a `Vector3int16` to the `Buwic`.
function Buwic.writeVector3int16(self: Buwic, vector: Vector3int16)
	resizeIfNeeded(self, 6)
	local b, c = self._buffer, self._cursor
	buffer.writei16(b, c, vector.X)
	buffer.writei16(b, c + 2, vector.Y)
	buffer.writei16(b, c + 4, vector.Z)
	self._cursor += 6
end

-- Roblox specific readers --

function Buwic.readAxes(self: Buwic): Axes
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 1, "attempt to read Axes out of bounds")
	local r = buffer.readu8(b, c)
	self._cursor += 1
	local axes = table.create(3)
	if bit32.btest(r, 0b100) then
		table.insert(axes, Enum.Axis.Z)
	end
	if bit32.btest(r, 0b010) then
		table.insert(axes, Enum.Axis.Y)
	end
	if bit32.btest(r, 0b001) then
		table.insert(axes, Enum.Axis.X)
	end

	return Axes.new(table.unpack(axes))
end

function Buwic.readBrickColor(self: Buwic): BrickColor
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 2, "attempt to read BrickColor out of bounds")
	local color = BrickColor.new(buffer.readu16(b, c))
	self._cursor += 2

	return color
end

function Buwic.readCFrame(self: Buwic): CFrame
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 48, "attempt to read CFrame out of bounds")
	--stylua: ignore
	local cf = CFrame.new(
		buffer.readf32(b, c), buffer.readf32(b, c + 4), buffer.readf32(b, c + 8),
		buffer.readf32(b, c + 12), buffer.readf32(b, c + 16), buffer.readf32(b, c + 20),
		buffer.readf32(b, c + 24), buffer.readf32(b, c + 28), buffer.readf32(b, c + 32),
		buffer.readf32(b, c + 36), buffer.readf32(b, c + 40), buffer.readf32(b, c + 44)
	)
	self._cursor += 48

	return cf
end

function Buwic.readColor3(self: Buwic): Color3
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 12, "attempt to read Color3 out of bounds")
	local color = Color3.fromRGB(buffer.readf32(b, c), buffer.readf32(b, c + 4), buffer.readf32(b, c + 8))
	self._cursor += 12

	return color
end

function Buwic.readColor3uint8(self: Buwic): Color3
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 3, "attempt to read Color3uint8 out of bounds")
	local color = Color3.fromRGB(buffer.readu8(b, c), buffer.readu8(b, c + 1), buffer.readu8(b, c + 2))
	self._cursor += 3

	return color
end

function Buwic.readColorSequence(self: Buwic): ColorSequence
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 4, "attempt to read ColorSequence out of bounds")
	local n = buffer.readu32(b, c)
	c += 4
	assert(buffer.len(b) >= c + (n * 16), "attempt to read ColorSequence out of bounds")

	local keypoints = table.create(n)
	for i = 0, n - 1 do
		keypoints[i + 1] = ColorSequenceKeypoint.new(
			buffer.readf32(b, c + (i * 16)),
			Color3.new(
				buffer.readf32(b, c + 4 + (i * 16)),
				buffer.readf32(b, c + 8 + (i * 16)),
				buffer.readf32(b, c + 12 + (i * 16))
			)
		)
	end

	self._cursor += n * 16

	return ColorSequence.new(keypoints)
end

function Buwic.readDateTime(self: Buwic): DateTime
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 8, "attempt to read DateTime out of bounds")
	local date = DateTime.fromUnixTimestampMillis(buffer.readf64(b, c))
	self._cursor += 8

	return date
end

function Buwic.readEnum(self: Buwic): EnumItem
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 6, "attempt to read DateTime out of bounds")
	local value = buffer.readu32(b, c)
	local nameLen = buffer.readu16(b, c + 4)
	assert(buffer.len(b) >= c + 6 + nameLen, "attempt to read DateTime out of bounds")
	local name = buffer.readstring(b, c + 6, nameLen)
	self._cursor += 6 + nameLen

	local enum = (Enum :: any)[name]
	for _, variant: EnumItem in enum:GetEnumItems() do
		if variant.Value == value then
			return variant
		end
	end
	error(string.format("no EnumItem with Value %d found as a member of %s", value, name), 2)
end

function Buwic.readFaces(self: Buwic): Faces
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 1, "attempt to read Faces out of bounds")
	local r = buffer.readu8(b, c)
	self._cursor += 1
	local faces = table.create(6)
	if bit32.btest(r, 0b100_000) then
		table.insert(faces, Enum.NormalId.Top)
	end
	if bit32.btest(r, 0b010_000) then
		table.insert(faces, Enum.NormalId.Left)
	end
	if bit32.btest(r, 0b001_000) then
		table.insert(faces, Enum.NormalId.Front)
	end
	if bit32.btest(r, 0b000_100) then
		table.insert(faces, Enum.NormalId.Bottom)
	end
	if bit32.btest(r, 0b000_010) then
		table.insert(faces, Enum.NormalId.Right)
	end
	if bit32.btest(r, 0b000_001) then
		table.insert(faces, Enum.NormalId.Back)
	end

	return Faces.new(table.unpack(faces))
end

function Buwic.readFont(self: Buwic): Font
	local b, c = self._buffer, self._cursor
	local style = NUMBER_TO_FONTSTYLE[buffer.readu8(b, c)]
	local weight = NUMBER_TO_FONTWEIGHT[buffer.readu16(b, c + 1)]
	local familyLen = buffer.readu16(b, c + 3)
	local family = buffer.readstring(b, c + 5, familyLen)

	self._cursor += 5 + familyLen

	return Font.new(family, weight, style)
end

function Buwic.readNumberRange(self: Buwic): NumberRange
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 8, "attempt to read NumberRange out of bounds")
	local range = NumberRange.new(buffer.readf32(b, c), buffer.readf32(b, c + 4))
	self._cursor += 8

	return range
end

function Buwic.readNumberSequence(self: Buwic): NumberSequence
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 4, "attempt to read NumberSequence out of bounds")
	local n = buffer.readu32(b, c)
	c += 4
	assert(buffer.len(b) >= c + (n * 12), "attempt to read NumberSequence out of bounds")

	local keypoints = table.create(n)
	for i = 0, n - 1 do
		keypoints[i + 1] = NumberSequenceKeypoint.new(
			buffer.readf32(b, c + (i * 16)),
			buffer.readf32(b, c + 4 + (i * 16)),
			buffer.readf32(b, c + 8 + (i * 16))
		)
	end

	self._cursor += n * 12

	return NumberSequence.new(keypoints)
end

function Buwic.readPhysicalProperties(self: Buwic): PhysicalProperties
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 20, "attempt to read PhysicalProperties out of bounds")
	local pp = PhysicalProperties.new(
		buffer.readf32(b, c),
		buffer.readf32(b, c + 4),
		buffer.readf32(b, c + 8),
		buffer.readf32(b, c + 12),
		buffer.readf32(b, c + 16)
	)
	self._cursor += 20

	return pp
end

function Buwic.readRay(self: Buwic): Ray
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 24, "attempt to read Ray out of bounds")
	local ray = Ray.new(
		Vector3.new(buffer.readf32(b, c), buffer.readf32(b, c + 4), buffer.readf32(b, c + 8)),
		Vector3.new(buffer.readf32(b, c + 12), buffer.readf32(b, c + 16), buffer.readf32(b, c + 20))
	)
	self._cursor += 24

	return ray
end

function Buwic.readRect(self: Buwic): Rect
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 16, "attempt to read Rect out of bounds")
	local rect =
		Rect.new(buffer.readf32(b, c), buffer.readf32(b, c + 4), buffer.readf32(b, c + 8), buffer.readf32(b, c + 12))
	self._cursor += 12

	return rect
end

function Buwic.readUDim(self: Buwic): UDim
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 8, "attempt to read UDim out of bounds")
	local udim = UDim.new(buffer.readf32(b, c), buffer.readi32(b, c + 4))
	self._cursor += 8

	return udim
end

function Buwic.readUDim2(self: Buwic): UDim2
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 16, "attempt to read UDim2 out of bounds")
	--stylua: ignore
	local udim2 = UDim2.new(
		buffer.readf32(b, c),
		buffer.readi32(b, c + 4),
		buffer.readf32(b, c + 8),
		buffer.readi32(b, c + 12)
	)
	self._cursor += 16

	return udim2
end

function Buwic.readVector2(self: Buwic): Vector2
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 8, "attempt to read Vector2 out of bounds")
	local vector = Vector2.new(buffer.readf32(b, c), buffer.readf32(b, c + 4))
	self._cursor += 8

	return vector
end

function Buwic.readVector2int16(self: Buwic): Vector2int16
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 4, "attempt to read Vector2int16 out of bounds")
	local vector = Vector2int16.new(buffer.readi16(b, c), buffer.readi16(b, c + 2))
	self._cursor += 4

	return vector
end

function Buwic.readVector3(self: Buwic): Vector3
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 12, "attempt to read Vector3 out of bounds")
	local vector = Vector3.new(buffer.readf32(b, c), buffer.readf32(b, c + 4), buffer.readf32(b, c + 8))
	self._cursor += 8

	return vector
end

function Buwic.readVector3int16(self: Buwic): Vector3int16
	local b, c = self._buffer, self._cursor
	assert(buffer.len(b) >= c + 6, "attempt to read Vector3int16 out of bounds")
	local vector = Vector3int16.new(buffer.readi16(b, c), buffer.readi16(b, c + 2), buffer.readi16(b, c + 4))
	self._cursor += 6

	return vector
end

return Buwic
