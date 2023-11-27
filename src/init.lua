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

--- Writes a u24 to the provided `Buwic`.
--- This is separate so that it can be inlined in both `Buwic.writeu24`
--- and `Buwic.writei24`.
local function writeu24(buwic: Buwic, n: number)
	resizeIfNeeded(buwic, 3)
	buffer.writeu8(buwic._buffer, buwic._cursor, bit32.band(n, 0xFF))
	buffer.writeu16(buwic._buffer, buwic._cursor + 1, bit32.rshift(n, 8))
	buwic._cursor += 3
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

--- Reads a u24 from the provided `Buwic`.
--- This is separate so that it can be inlined in both `Buwic.readu24`
--- and `Buwic.readi24`.
local function readu24(buwic: Buwic): number
	local n = buffer.readu16(buwic._buffer, buwic._cursor)
	buwic._cursor += 3
	return bit32.lshift(buffer.readu8(buwic._buffer, buwic._cursor - 1), 16) + n
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

return Buwic
