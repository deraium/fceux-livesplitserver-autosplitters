socket = require('socket')
sock = socket.connect("localhost", 16834)
address = {
	screen = 0x440,
	sound = 0x580,
	y = 0x4A0,
	boss_hp = 0x6C1,
	stage = 0x2A
}
start_screen_sound = 13
teleport_out_sound = 58
victory_sound = 21
game_start_sound = 255
refight_stage = 12
alien_stage = 13
previous = {}
current = {}


function reset()
	for k, v in pairs(address) do
		previous[k] = memory.readbyte(v)
	end
	emu.frameadvance()
	wait_for_teleport_out = false
	wait_for_teleport_down = false
	ship_life = 1
end

function reset_trigger()
	if current.sound == start_screen_sound and previous.sound ~= start_screen_sound and current.stage == 0 then
		sock:send("reset\r\n")
		reset()
		return true
	end
	return false
end

function start_trigger()
	if current.sound == game_start_sound and previous.sound ~= start_screen_sound then
		sock:send("starttimer\r\n")
		return true
	end
	return false
end

function split_trigger()
	if current.stage == alien_stage and current.boss_hp == 0 and previous.boss_hp > 0 then
		sock:send("split\r\n")
		return true
	end
	if current.stage == refight_stage and current.boss_hp == 0 and current.y >= 224 and previous.y < 224 then
		sock:send("split\r\n")
		return true
	end
	if wait_for_teleport_out and current.sound == teleport_out_sound and previous.y >= 8 and current.y < 8 then
		sock:send("split\r\n")
		wait_for_teleport_out = false
		return true
	end
	if not wait_for_teleport_out and current.sound == victory_sound then
		wait_for_teleport_out = true
	end
	return false
end

triggers = {reset_trigger, start_trigger, split_trigger}
reset()
while true do
	for k, v in pairs(address) do
		current[k] = memory.readbyte(v)
		--print(k, memory.readbyte(v))
	end
	for i=1, #triggers do
		triggers[i]()
	end
	for k, v in pairs(current) do
		previous[k] = current[k]
	end
	emu.frameadvance()
end
	
