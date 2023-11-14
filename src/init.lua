--!strict
--!optimize 2

local Buwic = {}
Buwic.__index = Buwic

export type Buwic = typeof(setmetatable(
	{} :: {
		_inner: buffer,
		_cursor: number,
	},
	Buwic
))

local function resizeIfNeeded(buwic: Buwic, more: number)
	local len = buffer.len(buwic._inner)
	if buwic._cursor + more > len then
		-- We could resize to the next power of two
		-- but it's unclear if that's what people want.
		-- local new = buffer.create(2 ^ (math.floor(math.log(len + more, 2)) + 1))
		local new = buffer.create(len + more)
		-- print(`resizing to {buffer.len(new)} from {len}`)
		buffer.copy(new, 0, buwic._inner, 0, len)
		buwic._inner = new
	end
end

function Buwic.new(): Buwic
	return setmetatable({
		_inner = buffer.create(0),
		_len = 0,
		_cursor = 0,
	}, Buwic)
end

function Buwic.withCapacity(capacity: number): Buwic
	return setmetatable({
		_inner = buffer.create(capacity),
		_len = 0,
		_cursor = 0,
	}, Buwic)
end

function Buwic.fromString(str: string): Buwic
	local self = Buwic.withCapacity(#str)
	buffer.writestring(self._inner, 0, str)
	return self
end

function Buwic.fromBuffer(buff: buffer): Buwic
	local self = Buwic.withCapacity(buffer.len(buff))
	buffer.copy(self._inner, 0, buff, buffer.len(buff))
	return self
end

-- Accesor methods --

function Buwic.toString(self: Buwic): string
	return buffer.readstring(self._inner, 0, buffer.len(self._inner))
end

function Buwic.capacity(self: Buwic): number
	return buffer.len(self._inner)
end

function Buwic.getCursor(self: Buwic): number
	return self._cursor
end

function Buwic.leakInner(self: Buwic): buffer
	return self._inner
end

-- Modifying methods --

function Buwic.setCursor(self: Buwic, location: number)
	self._cursor = location
end

function Buwic.reserve(self: Buwic, more: number)
	local len = buffer.len(self._inner)
	local new = buffer.create(len + more)
	-- print(`resizing to {buffer.len(new)} from {len}`)
	buffer.copy(new, 0, self._inner, 0, len)
	self._inner = new
end

--- Will move cursor to new len if it's already beyond the buffer end
function Buwic.shrink(self: Buwic, less: number)
	local len = buffer.len(self._inner)
	local new = buffer.create(math.max(len - less, 0))
	-- print(`shrinking to {buffer.len(new)} from {len}`)
	buffer.copy(new, 0, self._inner, 0, len - less)
	if self._cursor > buffer.len(new) then
		self._cursor = buffer.len(new)
	end
	self._inner = new
end

-- Basic Writers --

function Buwic.writeu8(self: Buwic, n: number)
	resizeIfNeeded(self, 1)
	buffer.writeu8(self._inner, self._cursor, n)
	self._cursor += 1
end

function Buwic.writei8(self: Buwic, n: number)
	resizeIfNeeded(self, 1)
	buffer.writei8(self._inner, self._cursor, n)
	self._cursor += 1
end

function Buwic.writeu16(self: Buwic, n: number)
	resizeIfNeeded(self, 2)
	buffer.writeu16(self._inner, self._cursor, n)
	self._cursor += 2
end

function Buwic.writei16(self: Buwic, n: number)
	resizeIfNeeded(self, 2)
	buffer.writei16(self._inner, self._cursor, n)
	self._cursor += 2
end

function Buwic.writeu24(self: Buwic, n: number)
	resizeIfNeeded(self, 3)
	buffer.writeu8(self._inner, self._cursor, bit32.band(n, 0xFF))
	buffer.writeu16(self._inner, self._cursor + 1, bit32.rshift(n, 8))
	self._cursor += 3
end

function Buwic.writei24(self: Buwic, n: number)
	self:writeu24(n % 0x1000_000)
end

function Buwic.writeu32(self: Buwic, n: number)
	resizeIfNeeded(self, 4)
	buffer.writeu32(self._inner, self._cursor, n)
	self._cursor += 4
end

function Buwic.writei32(self: Buwic, n: number)
	resizeIfNeeded(self, 4)
	buffer.writei32(self._inner, self._cursor, n)
	self._cursor += 4
end

function Buwic.writef32(self: Buwic, n: number)
	resizeIfNeeded(self, 4)
	buffer.writef32(self._inner, self._cursor, n)
	self._cursor += 4
end

function Buwic.writef64(self: Buwic, n: number)
	resizeIfNeeded(self, 8)
	buffer.writef64(self._inner, self._cursor, n)
	self._cursor += 8
end

function Buwic.writeRawString(self: Buwic, str: string, len: number?)
	resizeIfNeeded(self, len or #str)
	buffer.writestring(self._inner, self._cursor, str, if len then len else nil)
end

function Buwic.writeString(self: Buwic, str: string, len: number?)
	resizeIfNeeded(self, (len or #str) + 3)
	self:writeu24(len or #str)
	buffer.writestring(self._inner, self._cursor, str, if len then len else nil)
	self._cursor += #str
end

function Buwic.writeBuffer(self: Buwic, buff: buffer, len: number?)
	resizeIfNeeded(self, len or buffer.len(buff))
	buffer.copy(self._inner, self._cursor, buff, 0, len)
	self._cursor += len or buffer.len(buff)
end

-- Basic Readers --

function Buwic.readu8(self: Buwic): number
	local n = buffer.readu8(self._inner, self._cursor)
	self._cursor += 1
	return n
end

function Buwic.readi8(self: Buwic): number
	local n = buffer.readi8(self._inner, self._cursor)
	self._cursor += 1
	return n
end

function Buwic.readu16(self: Buwic): number
	local n = buffer.readu16(self._inner, self._cursor)
	self._cursor += 2
	return n
end

function Buwic.readi16(self: Buwic): number
	local n = buffer.readi16(self._inner, self._cursor)
	self._cursor += 2
	return n
end

function Buwic.readu24(self: Buwic): number
	local n = buffer.readu16(self._inner, self._cursor)
	self._cursor += 3
	return bit32.lshift(buffer.readu8(self._inner, self._cursor - 1), 16) + n
end

function Buwic.readi24(self: Buwic): number
	local n = self:readu24()
	return if n >= 0x800000 then n - 0x1000000 else n
end

function Buwic.readu32(self: Buwic): number
	local n = buffer.readu32(self._inner, self._cursor)
	self._cursor += 4
	return n
end

function Buwic.readi32(self: Buwic): number
	local n = buffer.readi32(self._inner, self._cursor)
	self._cursor += 4
	return n
end

function Buwic.readf32(self: Buwic): number
	local n = buffer.readf32(self._inner, self._cursor)
	self._cursor += 4
	return n
end

function Buwic.readf64(self: Buwic): number
	local n = buffer.readf64(self._inner, self._cursor)
	self._cursor += 8
	return n
end

function Buwic.readRawString(self: Buwic, len: number): string
	local str = buffer.readstring(self._inner, self._cursor, len)
	self._cursor += len
	return str
end

function Buwic.readString(self: Buwic): string
	local len = self:readu24()
	local str = buffer.readstring(self._inner, self._cursor, len)
	self._cursor += len
	return str
end

function Buwic.readBuffer(self: Buwic, len: number): buffer
	local out = buffer.create(len)
	buffer.copy(out, 0, self._inner, self._cursor, len)
	self._cursor += len
	return out
end

-- TODO: function for reading and writing vectors

return Buwic
