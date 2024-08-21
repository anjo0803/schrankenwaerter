
local SW = {
	version = "1.0.0",
	sleeping = {},
	crossings = {}
}


-- Crossing Actions

function SW.wait(duration)
	return function(crossing_id)
		SW.crossings[crossing_id].rundata.sleep = duration
		table.insert(SW.sleeping, crossing_id)
		return false
	end
end

function SW.signal(signal_id, position)
	if EEPVer < 10.2 then return function (_) end end
	return function(_)
		EEPSetSignal(signal_id, position)
		return true
	end
end

function SW.immo(immo_id, axis, step)
	if EEPVer < 11.1 then return function (_) end end
	return function(_)
		EEPStructureAnimateAxis(immo_id, axis, step)
		return true
	end
end

function SW.sound(sound_id, turn_on)
	if EEPVer < 13.1 then return function (_) end end
	return function(_)
		EEPStructurePlaySound(sound_id, turn_on)
		return true
	end
end

function SW.setup(...)
	SW.crossings = ...
	for _, crossing in pairs(SW.crossings) do
		-- Move the declared opening and closing sequences to routines
		crossing.routines = { crossing.closing, crossing.opening }

		-- Initialize the data that will be used during execution
		crossing.rundata = {
			trains = 0,
			sleep = 0,
			routine = {}
		}

		-- If a save slot exists, load the saved number of trains
		if crossing.slot ~= nil and EEPVer >= 11 then
			local save_exists, saved_trains = EEPLoadData(crossing.slot)
			if save_exists then crossing.rundata.trains = saved_trains end
		end
	end
	print("Schrankenwaerter ", SW.version, " set up!")
end

-- Execution

function SW.main()
	-- Record the resumed crossings first, so they aren't removed from the
	-- source table while iterating it.
	local resumed = {}
	for index, crossing_id in ipairs(SW.sleeping) do
		local rundata = SW.crossings[crossing_id].rundata
		if rundata.sleep <= 0 then
			resumed[crossing_id] = index
		else
			rundata.sleep = rundata.sleep - 1
		end
	end

	for crossing_id, sleep_index in pairs(resumed) do
		SW.do_routine(crossing_id)
		table.remove(SW.sleeping, sleep_index)
	end
end

function SW.crossingClose(crossing_id)
	if SW.update_and_get_trains(crossing_id, 1) > 1 then return end
	if SW.load_routine(crossing_id, 1) then SW.do_routine(crossing_id) end
end

function SW.crossingOpen(crossing_id)
	if SW.update_and_get_trains(crossing_id, -1) > 0 then return end
	if SW.load_routine(crossing_id, 2) then SW.do_routine(crossing_id) end
end

function SW.update_and_get_trains(crossing_id, step)
	local crossing = SW.crossings[crossing_id]
	crossing.rundata.trains = crossing.rundata.trains + step
	if crossing.rundata.trains < 0 then crossing.rundata.trains = 0 end

	if crossing.slot ~= nil and EEPVer >= 11 then
		EEPSaveData(crossing.slot, crossing.rundata.trains)
	end

	return crossing.rundata.trains
end

function SW.load_routine(crossing_id, routine_id)
	-- Load the crossing and confirm all necessary data exists
	local crossing = SW.crossings[crossing_id]
	if crossing == nil then return false end

	-- Load the appropriate routine
	local actions = crossing.routines[routine_id]
	if actions == nil then return false end

	-- Copy it to the rundata, since executed statements will be deleted
	crossing.rundata.routine = {}
	for k, v in pairs(actions) do
		crossing.rundata.routine[k] = v
	end
	return true
end

function SW.do_routine(crossing_id)
	local routine = SW.crossings[crossing_id].rundata.routine
	while #routine > 0 do
		local continue = routine[1](crossing_id)
		table.remove(routine, 1)
		if not continue then break end
	end
end

return SW
