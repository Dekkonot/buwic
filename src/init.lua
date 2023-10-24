--!strict
--!optimize 2

local Buwic = {}
Buwic.__index = Buwic

export type Buwic = typeof(setmetatable({} :: {
	_inner: buffer,
	_cursor: number,
}, Buwic))

local function resizeIfNeeded(buwic: Buwic, more: number)
	local len = buffer.len(buwic._inner)
	if buwic._cursor + more > len then
		-- We could resize to the next power of two
		-- but it's unclear if that's what people want.
		-- local new = buffer.create(2 ^ (math.floor(math.log(len + more, 2)) + 1))
		local new = buffer.create(len + more)
		print(`resizing to {buffer.len(new)} from {len}`)
		buffer.copy(buwic._inner, 0, len, 0, new)
		buwic._inner = new
	end
end

function Buwic.new(): Buwic
	return setmetatable({
		_inner = buffer.create(0),
		_cursor = 0,
	}, Buwic)
end

function Buwic.withCapacity(capacity: number): Buwic
	return setmetatable({
		_inner = buffer.create(capacity),
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
	buffer.copy(buff, 0, buffer.len(buff), 0, self._inner)
	return self
end

function Buwic.reserve(self: Buwic, more: number)
	local len = buffer.len(self._inner)
	local new = buffer.create(len + more)
	print(`resizing to {buffer.len(new)} from {len}`)
	buffer.copy(self._inner, 0, len, 0, new)
	self._inner = new
end

--- Will move cursor to new len if it's already beyond the buffer end
function Buwic.shrink(self: Buwic, less: number)
	local len = buffer.len(self._inner)
	local new = buffer.create(math.max(len - less, 0))
	print(`shrinking to {buffer.len(new)} from {len}`)
	buffer.copy(self._inner, 0, len - less, 0, new)
	if self._cursor > buffer.len(new) then
		self._cursor = buffer.len(new)
	end
	self._inner = new
end

function Buwic.setCursor(self: Buwic, location: number)
	self._cursor = location
end

function Buwic.toString(self: Buwic): string
	return buffer.readstring(self._inner, 0, buffer.len(self._inner))
end

function Buwic.writeString(self: Buwic, str: string)
	resizeIfNeeded(self, #str)
	buffer.writestring(self._inner, self._cursor, str)
	self._cursor += #str
end

function Buwic.writeu8(self: Buwic, n: number)
	resizeIfNeeded(self, 1)
	buffer.writeu8(self._inner, self._cursor, n)
	self._cursor += 1
end

local buffer = Buwic.new()

buffer:reserve(10)
buffer:writeString("wow!")
buffer:writeString("again!")
print(buffer.toString(buffer))
buffer:shrink(6)
print(buffer.toString(buffer))
buffer:writeString("again!")
print(buffer.toString(buffer))

return Buwic
