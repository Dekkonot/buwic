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

local NUMBER_TO_FONTSTYLE = {}
local NUMBER_TO_FONTWEIGHT = {}

for _, item: Enum.FontStyle in Enum.FontStyle:GetEnumItems() do
	NUMBER_TO_FONTSTYLE[item.Value] = item
end
for _, item: Enum.FontWeight in Enum.FontWeight:GetEnumItems() do
	NUMBER_TO_FONTWEIGHT[item.Value] = item
end

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

function Buwic.new(capacity: number?): Buwic
	return setmetatable({
		_buffer = buffer.create(capacity or 0),
		-- This is a load bearing field. I assume it's a cache thing but I don't know.
		_len = 0,
		_cursor = 0,
	}, Buwic)
end

function Buwic.fromString(str: string): Buwic
	local self = Buwic.new(#str)
	buffer.writestring(self._buffer, 0, str)
	return self
end

function Buwic.fromBuffer(buff: buffer): Buwic
	local self = Buwic.new(buffer.len(buff))
	buffer.copy(self._buffer, 0, buff, buffer.len(buff))
	return self
end

-- Accesor methods --

function Buwic.toString(self: Buwic): string
	return buffer.readstring(self._buffer, 0, buffer.len(self._buffer))
end

function Buwic.capacity(self: Buwic): number
	return buffer.len(self._buffer)
end

function Buwic.getCursor(self: Buwic): number
	return self._cursor
end

function Buwic.leak(self: Buwic): buffer
	return self._buffer
end

-- Modifying methods --

function Buwic.setCursor(self: Buwic, location: number)
	self._cursor = location
end

function Buwic.reserve(self: Buwic, more: number)
	local len = buffer.len(self._buffer)
	local new = buffer.create(len + more)
	-- print(`resizing to {buffer.len(new)} from {len}`)
	buffer.copy(new, 0, self._buffer, 0, len)
	self._buffer = new
end

--- Will move cursor to new len if it's already beyond the buffer end
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

function Buwic.writeu8(self: Buwic, n: number)
	resizeIfNeeded(self, 1)
	buffer.writeu8(self._buffer, self._cursor, n)
	self._cursor += 1
end

function Buwic.writei8(self: Buwic, n: number)
	resizeIfNeeded(self, 1)
	buffer.writei8(self._buffer, self._cursor, n)
	self._cursor += 1
end

function Buwic.writeu16(self: Buwic, n: number)
	resizeIfNeeded(self, 2)
	buffer.writeu16(self._buffer, self._cursor, n)
	self._cursor += 2
end

function Buwic.writei16(self: Buwic, n: number)
	resizeIfNeeded(self, 2)
	buffer.writei16(self._buffer, self._cursor, n)
	self._cursor += 2
end

function Buwic.writeu24(self: Buwic, n: number)
	writeu24(self, n)
end

function Buwic.writei24(self: Buwic, n: number)
	writeu24(self, n % 0x1000_000)
end

function Buwic.writeu32(self: Buwic, n: number)
	resizeIfNeeded(self, 4)
	buffer.writeu32(self._buffer, self._cursor, n)
	self._cursor += 4
end

function Buwic.writei32(self: Buwic, n: number)
	resizeIfNeeded(self, 4)
	buffer.writei32(self._buffer, self._cursor, n)
	self._cursor += 4
end

function Buwic.writef32(self: Buwic, n: number)
	resizeIfNeeded(self, 4)
	buffer.writef32(self._buffer, self._cursor, n)
	self._cursor += 4
end

function Buwic.writef64(self: Buwic, n: number)
	resizeIfNeeded(self, 8)
	buffer.writef64(self._buffer, self._cursor, n)
	self._cursor += 8
end

function Buwic.writeRawString(self: Buwic, str: string, len: number?)
	resizeIfNeeded(self, len or #str)
	buffer.writestring(self._buffer, self._cursor, str, len)
	self._cursor += len or #str
end

function Buwic.writeString(self: Buwic, str: string, len: number?)
	resizeIfNeeded(self, (len or #str) + 4)
	buffer.writeu32(self._buffer, self._cursor, len or #str)
	buffer.writestring(self._buffer, self._cursor + 4, str, len)
	self._cursor += #str + 4
end

function Buwic.writeBuffer(self: Buwic, buff: buffer, len: number?)
	resizeIfNeeded(self, len or buffer.len(buff))
	buffer.copy(self._buffer, self._cursor, buff, 0, len)
	self._cursor += len or buffer.len(buff)
end

-- Basic Readers --

function Buwic.readu8(self: Buwic): number
	local n = buffer.readu8(self._buffer, self._cursor)
	self._cursor += 1
	return n
end

function Buwic.readi8(self: Buwic): number
	local n = buffer.readi8(self._buffer, self._cursor)
	self._cursor += 1
	return n
end

function Buwic.readu16(self: Buwic): number
	local n = buffer.readu16(self._buffer, self._cursor)
	self._cursor += 2
	return n
end

function Buwic.readi16(self: Buwic): number
	local n = buffer.readi16(self._buffer, self._cursor)
	self._cursor += 2
	return n
end

function Buwic.readu24(self: Buwic): number
	return readu24(self)
end

function Buwic.readi24(self: Buwic): number
	local n = readu24(self)
	return if n >= 0x800000 then n - 0x1000000 else n
end

function Buwic.readu32(self: Buwic): number
	local n = buffer.readu32(self._buffer, self._cursor)
	self._cursor += 4
	return n
end

function Buwic.readi32(self: Buwic): number
	local n = buffer.readi32(self._buffer, self._cursor)
	self._cursor += 4
	return n
end

function Buwic.readf32(self: Buwic): number
	local n = buffer.readf32(self._buffer, self._cursor)
	self._cursor += 4
	return n
end

function Buwic.readf64(self: Buwic): number
	local n = buffer.readf64(self._buffer, self._cursor)
	self._cursor += 8
	return n
end

function Buwic.readRawString(self: Buwic, len: number): string
	local str = buffer.readstring(self._buffer, self._cursor, len)
	self._cursor += len
	return str
end

function Buwic.readString(self: Buwic): string
	local len = buffer.readu32(self._buffer, self._cursor)
	local str = buffer.readstring(self._buffer, self._cursor + 4, len)
	self._cursor += len + 4
	return str
end

function Buwic.readBuffer(self: Buwic, len: number): buffer
	local out = buffer.create(len)
	buffer.copy(out, 0, self._buffer, self._cursor, len)
	self._cursor += len
	return out
end

-- TODO: function for reading and writing vectors

-- Roblox specific writers --

function Buwic.writeAxes(self: Buwic, axes: Axes)
	resizeIfNeeded(self, 1)
	buffer.writeu8(
		self._buffer,
		self._cursor,
		(axes.Z and 0b100 or 0b000) + (axes.Y and 0b010 or 0b000) + (axes.X and 0b001 or 0b000)
	)
	self._cursor += 1
end

function Buwic.writeBrickColor(self: Buwic, color: BrickColor)
	resizeIfNeeded(self, 2)
	buffer.writeu16(self._buffer, self._cursor, color.Number)
	self._cursor += 2
end

--- Writes a CFrame as 12 `f32`s.
function Buwic.writeCFrame(self: Buwic, cframe: CFrame)
	resizeIfNeeded(self, 12 * 3)
	local b, c = self._buffer, self._cursor
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cframe:GetComponents()
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

function Buwic.writeColor3(self: Buwic, color: Color3)
	resizeIfNeeded(self, 12)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, color.R)
	buffer.writef32(b, c + 4, color.G)
	buffer.writef32(b, c + 8, color.B)
	self._cursor += 12
end

function Buwic.writeColor3uint8(self: Buwic, color: Color3)
	resizeIfNeeded(self, 3)
	local b, c = self._buffer, self._cursor
	buffer.writeu8(b, c, math.floor(color.R * 255))
	buffer.writeu8(b, c + 4, math.floor(color.G * 255))
	buffer.writeu8(b, c + 8, math.floor(color.B * 255))
	self._cursor += 3
end

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

function Buwic.writeDateTime(self: Buwic, date: DateTime)
	resizeIfNeeded(self, 8)
	buffer.writef64(self._buffer, self._cursor, date.UnixTimestampMillis)
	self._cursor += 8
end

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

function Buwic.writeNumberRange(self: Buwic, range: NumberRange)
	resizeIfNeeded(self, 8)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, range.Min)
	buffer.writef32(b, c + 4, range.Max)
	self._cursor += 8
end

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

function Buwic.writePhysicalProperties(self: Buwic, physicalProperties: PhysicalProperties) end

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

function Buwic.writeRect(self: Buwic, rect: Rect)
	resizeIfNeeded(self, 16)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, rect.Min.X)
	buffer.writef32(b, c + 4, rect.Min.Y)
	buffer.writef32(b, c + 8, rect.Max.X)
	buffer.writef32(b, c + 12, rect.Max.Y)
	self._cursor += 16
end

function Buwic.writeUDim(self: Buwic, udim: UDim)
	resizeIfNeeded(self, 8)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, udim.Scale)
	buffer.writei32(b, c + 4, udim.Offset)
	self._cursor += 8
end

function Buwic.writeUDim2(self: Buwic, udim2: UDim2)
	resizeIfNeeded(self, 16)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, udim2.X.Scale)
	buffer.writei32(b, c + 4, udim2.X.Offset)
	buffer.writef32(b, c + 8, udim2.Y.Scale)
	buffer.writei32(b, c + 12, udim2.Y.Offset)
	self._cursor += 16
end

function Buwic.writeVector2(self: Buwic, vector: Vector2)
	resizeIfNeeded(self, 8)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, vector.X)
	buffer.writef32(b, c + 4, vector.Y)
	self._cursor += 8
end

function Buwic.writeVector2int16(self: Buwic, vector: Vector2int16)
	resizeIfNeeded(self, 4)
	local b, c = self._buffer, self._cursor
	buffer.writei16(b, c, vector.X)
	buffer.writei16(b, c + 2, vector.Y)
	self._cursor += 4
end

function Buwic.writeVector3(self: Buwic, vector: Vector3)
	resizeIfNeeded(self, 12)
	local b, c = self._buffer, self._cursor
	buffer.writef32(b, c, vector.X)
	buffer.writef32(b, c + 4, vector.Y)
	buffer.writef32(b, c + 8, vector.Z)
	self._cursor += 12
end

function Buwic.writeVector3int16(self: Buwic, vector: Vector3int16)
	resizeIfNeeded(self, 6)
	local b, c = self._buffer, self._cursor
	buffer.writei16(b, c, vector.X)
	buffer.writei16(b, c + 2, vector.Y)
	buffer.writei16(b, c + 4, vector.Z)
	self._cursor += 6
end

-- Roblox specific readers --

function Buwic.readFont(self: Buwic): Font
	local b, c = self._buffer, self._cursor
	local style = NUMBER_TO_FONTSTYLE[buffer.readu8(b, c)]
	local weight = NUMBER_TO_FONTWEIGHT[buffer.readu16(b, c + 1)]
	local familyLen = buffer.readu16(b, c + 3)
	local family = buffer.readstring(b, c + 5, familyLen)

	self._cursor += 5 + familyLen

	return Font.new(family, weight, style)
end

return Buwic
