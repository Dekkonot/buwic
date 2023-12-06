local Buwic = require("src/init")

print("Testing every possible u8 in roundtrip")
local u8_test = Buwic.new(1)
for i = 0, 0xFF do
	assert(u8_test:capacity() == 1, "capacity was not 1 during u8 testing")
	u8_test:writeu8(i)
	assert(u8_test:getCursor() == 1, "cursor was not moved by writeu8")
	u8_test:setCursor(0)
	assert(u8_test:getCursor() == 0, "cursor was not moved by setCursor")
	local n = u8_test:toString()
	assert(n == string.pack("<I1", i), `writeu8 did not write value {i} correctly`)

	local read = u8_test:readu8()
	assert(read == i, `readu8 did not read value {i} correctly`)
	assert(u8_test:getCursor() == 1, "cursor was not moved by readu8")
	u8_test:setCursor(0)
end
assert(u8_test:capacity() == 1, "capacity was not 1 after u8 testing")
u8_test:writeu8(00)
u8_test:writeu8(00)
assert(u8_test:capacity() == 2, "readu8 did not expand buffer appropriately")

print("Testing every possible i8 in roundtrip")
local i8_test = Buwic.new(1)
for i = -0x80, 0x7F do
	assert(i8_test:capacity() == 1, "capacity was not 1 during i8 testing")
	i8_test:writei8(i)
	assert(i8_test:getCursor() == 1, "cursor was not moved by writei8")
	i8_test:setCursor(0)
	local n = i8_test:toString()
	assert(n == string.pack("<i1", i), `writei8 did not write value {i} correctly`)

	local read = i8_test:readi8()
	assert(read == i, `readi8 did not read value {i} correctly`)
	assert(i8_test:getCursor() == 1, "cursor was not moved by readi8")
	i8_test:setCursor(0)
end
assert(i8_test:capacity() == 1, "capacity was not 1 after i8 testing")
i8_test:writei8(00)
i8_test:writei8(00)
assert(i8_test:capacity() == 2, "readi8 did not expand buffer appropriately")

print("Testing every possible u16 in roundtrip")
local u16_test = Buwic.new(2)
for i = 0, 0xFFFF do
	assert(u16_test:capacity() == 2, "capacity was not 2 during u16 testing")
	u16_test:writeu16(i)
	assert(u16_test:getCursor() == 2, "cursor was not moved by writeu16")
	u16_test:setCursor(0)
	assert(u16_test:getCursor() == 0, "cursor was not moved by setCursor")
	local n = u16_test:toString()
	assert(n == string.pack("<I2", i), `writeu16 did not write value {i} correctly`)

	local read = u16_test:readu16()
	assert(read == i, `writeu16 did not read value {i} correctly`)
	assert(u16_test:getCursor() == 2, "cursor was not moved by writeu16")
	u16_test:setCursor(0)
end
assert(u16_test:capacity() == 2, "capacity was not 2 after u16 testing")
u16_test:writeu16(00)
u16_test:writeu16(00)
assert(u16_test:capacity() == 4, "writeu16 did not expand buffer appropriately")

print("Testing every possible i16 in roundtrip")
local i16_test = Buwic.new(2)
for i = -0x8000, 0x7F00 do
	assert(i16_test:capacity() == 2, "capacity was not 2 during i16 testing")
	i16_test:writei16(i)
	assert(i16_test:getCursor() == 2, "cursor was not moved by writei16")
	i16_test:setCursor(0)
	local n = i16_test:toString()
	assert(n == string.pack("<i2", i), `writei16 did not write value {i} correctly`)

	local read = i16_test:readi16()
	assert(read == i, `readi16 did not read value {i} correctly`)
	assert(i16_test:getCursor() == 2, "cursor was not moved by readi16")
	i16_test:setCursor(0)
end
assert(i16_test:capacity() == 2, "capacity was not 2 after i16 testing")
i16_test:writei16(00)
i16_test:writei16(00)
assert(i16_test:capacity() == 4, "writei16 did not expand buffer appropriately")

print("Testing every possible u24 in roundtrip")
local u24_test = Buwic.new(3)
for i = 0, 0xFFFFFF do
	assert(u24_test:capacity() == 3, "capacity was not 3 during u24 testing")
	u24_test:writeu24(i)
	assert(u24_test:getCursor() == 3, "cursor was not moved by writeu24")
	u24_test:setCursor(0)
	assert(u24_test:getCursor() == 0, "cursor was not moved by setCursor")
	local n = u24_test:toString()
	assert(n == string.pack("<I3", i), `writeu24 did not write value {i} correctly`)

	local read = u24_test:readu24()
	assert(read == i, `readu24 did not read value {i} correctly`)
	assert(u24_test:getCursor() == 3, "cursor was not moved by readu24")
	u24_test:setCursor(0)
end
assert(u24_test:capacity() == 3, "capacity was not 3 after u24 testing")
u24_test:writeu24(00)
u24_test:writeu24(00)
assert(u24_test:capacity() == 6, "writeu24 did not expand buffer appropriately")

print("Testing every possible i24 in roundtrip")
local i24_test = Buwic.new(3)
for i = -0x800000, 0x7FFFFF do
	assert(i24_test:capacity() == 3, "capacity was not 3 during i24 testing")
	i24_test:writei24(i)
	assert(i24_test:getCursor() == 3, "cursor was not moved by writei24")
	i24_test:setCursor(0)
	assert(i24_test:getCursor() == 0, "cursor was not moved by setCursor")
	local n = i24_test:toString()
	assert(n == string.pack("<i3", i), `writei24 did not write value {i} correctly`)

	local read = i24_test:readi24()
	assert(read == i, `readi24 did not read value {i} correctly`)
	assert(i24_test:getCursor() == 3, "cursor was not moved by readi24")
	i24_test:setCursor(0)
end
assert(i24_test:capacity() == 3, "capacity was not 3 after i24 testing")
i24_test:writei24(00)
i24_test:writei24(00)
assert(i24_test:capacity() == 6, "writei24 did not expand buffer appropriately")

print("Testing read/writeu32 with every u24")
local u32_test = Buwic.new(4)
for i = 0, 0xFFFFFF do
	assert(u32_test:capacity() == 4, "capacity was not 4 during u32 testing")
	u32_test:writeu32(i)
	assert(u32_test:getCursor() == 4, "cursor was not moved by writeu32")
	u32_test:setCursor(0)
	assert(u32_test:getCursor() == 0, "cursor was not moved by setCursor")
	local n = u32_test:toString()
	assert(n == string.pack("<I4", i), `writeu32 did not write value {i} correctly`)

	local read = u32_test:readu32()
	assert(read == i, `readu32 did not read value {i} correctly`)
	assert(u32_test:getCursor() == 4, "cursor was not moved by readu32")
	u32_test:setCursor(0)
end

print("Testing maximum value for read/writeu32")
do
	assert(u32_test:capacity() == 4, "capacity was not 4 during u32 testing")
	u32_test:writeu32(0xFFFFFFFF)
	assert(u32_test:getCursor() == 4, "cursor was not moved by writeu32")
	u32_test:setCursor(0)
	assert(u32_test:getCursor() == 0, "cursor was not moved by setCursor")
	local n = u32_test:toString()
	assert(n == string.pack("<I4", 0xFFFFFFFF), `writeu32 did not write value {0xFFFFFFFF} correctly`)

	local read = u32_test:readu32()
	assert(read == 0xFFFFFFFF, `readu32 did not read value {0xFFFFFFFF} correctly`)
	assert(u32_test:getCursor() == 4, "cursor was not moved by readu32")
	u32_test:setCursor(0)
end
assert(u32_test:capacity() == 4, "capacity was not 4 after u32 testing")
u32_test:writeu32(00)
u32_test:writeu32(00)
assert(u32_test:capacity() == 8, "writeu32 did not expand buffer appropriately")

print("Testing read/writei32 with every i24")
local i32_test = Buwic.new(4)
for i = -0x800000, 0x7FFFFF do
	assert(i32_test:capacity() == 4, "capacity was not 4 during i32 testing")
	i32_test:writei32(i)
	assert(i32_test:getCursor() == 4, "cursor was not moved by writei32")
	i32_test:setCursor(0)
	assert(i32_test:getCursor() == 0, "cursor was not moved by setCursor")
	local n = i32_test:toString()
	assert(n == string.pack("<i4", i), `writei32 did not write value {i} correctly`)

	local read = i32_test:readi32()
	assert(read == i, `readi32 did not read value {i} correctly`)
	assert(i32_test:getCursor() == 4, "cursor was not moved by readi32")
	i32_test:setCursor(0)
end

print("Testing minimum and maximum value for read/writei32")
do
	assert(i32_test:capacity() == 4, "capacity was not 4 during i32 testing")
	i32_test:writei32(-0x80000000)
	assert(i32_test:getCursor() == 4, "cursor was not moved by writei32")
	i32_test:setCursor(0)
	assert(i32_test:getCursor() == 0, "cursor was not moved by setCursor")
	local n = i32_test:toString()
	assert(n == string.pack("<i4", -0x80000000), `writei32 did not write value {-0x80000000} correctly`)

	local read = i32_test:readi32()
	assert(read == -0x80000000, `readi32 did not read value {-0x80000000} correctly`)
	assert(i32_test:getCursor() == 4, "cursor was not moved by readi32")
	i32_test:setCursor(0)
end

do
	assert(i32_test:capacity() == 4, "capacity was not 4 during i32 testing")
	i32_test:writei32(0x7FFFFFFF)
	assert(i32_test:getCursor() == 4, "cursor was not moved by writei32")
	i32_test:setCursor(0)
	assert(i32_test:getCursor() == 0, "cursor was not moved by setCursor")
	local n = i32_test:toString()
	assert(n == string.pack("<i4", 0x7FFFFFFF), `writei32 did not write value {0x7FFFFFFF} correctly`)

	local read = i32_test:readi32()
	assert(read == 0x7FFFFFFF, `readi32 did not read value {0x7FFFFFFF} correctly`)
	assert(i32_test:getCursor() == 4, "cursor was not moved by readi32")
	i32_test:setCursor(0)
end
assert(i32_test:capacity() == 4, "capacity was not 4 after i32 testing")
i32_test:writei32(00)
i32_test:writei32(00)
assert(i32_test:capacity() == 8, "writei32 did not expand buffer appropriately")

return true
