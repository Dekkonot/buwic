local Buwic = require("src/init")

-- I would normally also want to test NaN and subnormal numbers but...
-- If these all pass, we know that writef32 and readf32 are working so any bugs
-- are Roblox's fault!
local f32_tests = {
	0,
	1,
	-1,
	0.15625,
	-0.15625,
	2 ^ 23 - 1,
	-2 ^ 23 - 1,
	math.huge,
	-math.huge,
}

local f32_test = Buwic.new(4)

for _, n in f32_tests do
	assert(f32_test:capacity() == 4, "capacity was not 4 during f32 testing")
	f32_test:writef32(n)
	assert(f32_test:getCursor() == 4, "writef32 did not set cursor correctly")
	f32_test:setCursor(0)
	assert(f32_test:getCursor() == 0, "setCursor did not set cursor correctly")
	local s = f32_test:toString()
	assert(s == string.pack("<f", n), `writef32 failed to write {n} correctly`)

	local read = f32_test:readf32()
	assert(read == n, `readf32 did not read value {n} correctly`)
	assert(f32_test:getCursor() == 4, "cursor was not moved by readf32")
	f32_test:setCursor(0)
end
assert(f32_test:capacity() == 4, "capacity was not 4 after f32 testing")
f32_test:writef32(00)
f32_test:writef32(00)
assert(f32_test:capacity() == 8, "writef32 did not expand buffer appropriately")

local f64_tests = {
	0,
	1,
	-1,
	0.15625,
	-0.15625,
	2 ^ 53 - 1,
	-2 ^ 53 - 1,
	math.huge,
	-math.huge,
}

local f64_test = Buwic.new(8)

for _, n in f64_tests do
	assert(f64_test:capacity() == 8, "capacity was not 8 during f64 testing")
	f64_test:writef64(n)
	assert(f64_test:getCursor() == 8, "writef64 did not set cursor correctly")
	f64_test:setCursor(0)
	assert(f64_test:getCursor() == 0, "setCursor did not set cursor correctly")
	local s = f64_test:toString()
	assert(s == string.pack("<d", n), `writef64 failed to write {n} correctly`)

	local read = f64_test:readf64()
	assert(read == n, `readf64 did not read value {n} correctly`)
	assert(f64_test:getCursor() == 8, "cursor was not moved by readf64")
	f64_test:setCursor(0)
end
assert(f64_test:capacity() == 8, "capacity was not 8 after f64 testing")
f64_test:writef64(00)
f64_test:writef64(00)
assert(f64_test:capacity() == 16, "writef64 did not expand buffer appropriately")

return {}
