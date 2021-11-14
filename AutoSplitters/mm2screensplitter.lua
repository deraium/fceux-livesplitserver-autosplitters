socket = require('socket')
sock = socket.connect("localhost", 16834)
screen_address = 0x440
sound_address = 0x580
mega_man_y_address = 0x4A0
boss_hp_address = 0x6C1
choose_stage_sound = 12
start_screen_sound = 13
teleport_sound = 48
teleport_out_sound = 58
victory_sound = 21


function reset()
	previous_screen = memory.readbyte(screen_address)
	previous_sound = memory.readbyte(sound_address)
	previous_mega_man_y = memory.readbyte(mega_man_y_address)
	previous_boss_hp = memory.readbyte(boss_hp_address)
	emu.frameadvance()
	current_screen = memory.readbyte(screen_address)
	current_sound = memory.readbyte(sound_address)
	current_mega_man_y = memory.readbyte(mega_man_y_address)
	current_boss_hp = memory.readbyte(boss_hp_address)
	passed_screen = {}
	wait_for_teleport_out = false
	wait_for_teleport_in = true
end

function is_screen_passed(screen)
	for i=1,#passed_screen do
		if passed_screen[i] == screen then
			return true
		end
	end
	return false
end

function pass_screen(screen)
	passed_screen[#passed_screen+1] = screen
end

function reset_trigger()
	if previous_sound ~= start_screen_sound and current_sound == start_screen_sound then
		sock:send("reset\r\n")
		reset()
		return true
	end
	if previous_sound ~= choose_stage_sound and current_sound == choose_stage_sound then
		--sock:send("reset\r\n")
		reset()
	end
	return false
end

function start_trigger()
	if wait_for_teleport_in and previous_sound ~= teleport_sound and current_sound == teleport_sound then
		sock:send("starttimer\r\n")
		wait_for_teleport_in = false
		return true
	end
	return false
end

function split_trigger()
	if wait_for_teleport_out and current_sound == teleport_out_sound and previous_mega_man_y >= 8 and current_mega_man_y < 8 then
		sock:send("split\r\n")
		wait_for_teleport_out = false
		return true
	end
	if not wait_for_teleport_in and current_mega_man_y ~= 0 and previous_screen ~= current_screen and not is_screen_passed(current_screen) then
		sock:send("split\r\n")
		pass_screen(current_screen)
		return true
	end
	if not wait_for_teleport_out and current_sound == victory_sound then
		wait_for_teleport_out = true
	end
	return false
end

triggers = {reset_trigger, start_trigger, split_trigger}
reset()
while true do
	for i=1, #triggers do
		triggers[i]()
	end
	previous_screen = current_screen
	previous_sound = current_sound
	previous_mega_man_y = current_mega_man_y
	previous_boss_hp = current_boss_hp
	current_screen = memory.readbyte(screen_address)
	current_sound = memory.readbyte(sound_address)
	current_mega_man_y = memory.readbyte(mega_man_y_address)
	current_boss_hp = memory.readbyte(boss_hp_address)
	emu.frameadvance()
end
	
