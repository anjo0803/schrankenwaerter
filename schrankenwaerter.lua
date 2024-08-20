---------- SCHRANKENWAERTER START ----------
SW = { version = "1.0.0" }

--[[ NUTZUNG // USAGE ]]--
-- Sie können Ihre Bahnübergänge in der Funktion direkt unter diesem Kommentar
-- beschreiben. Fügen Sie bitte außerdem einen Aufruf der Funktion SW.main in
-- Ihre EEPMain-Funktion ein, um den SW.wait-Befehl nutzen zu können.
-- You can describe your railroad crossings in the function directly below this
-- comment. Please also call the SW.main function within your EEPMain function
-- to be able to use the SW.wait command.

function SW.CROSSING_CONFIG() return {
	-- BÜS HIER BESCHREIBEN // DESCRIBE CROSSINGS HERE
	--[[ BÜ-Datenstruktur // Crossing Data Structure:
		- slot: string (optional)
		- closing: {
			- Liste von Befehlen, z.B. SW.signal(id, stellung)
			- List of commands, e.g. SW.signal(id, position)
		}
		- opening: Wie "closing" // Like "closing"
	]]
} end

-- Ab hier rein interne Funktionalität -- Internal functionality only from here

SW.is_initialized = false
SW.sleeping = {}

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

-- Execution

function SW.init()
	if SW.is_initialized then return end	-- Prevent multiple init calls

	SW.crossings = SW.CROSSING_CONFIG()
	for _, crossing in pairs(SW.crossings) do
		-- Move the declared opening and closing sequences to routines
		crossing.routines = { crossing.closing, crossing.opening }

		-- Initialize the necessary rundata
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
	SW.is_initialized = true
	print("Schrankenwärter ", SW.version, " aktiv")
end

function SW.main()
	-- Confirm that the necessary rundata has been set up
	if not SW.is_initialized then SW.init() end

	-- Advance the timeout for all paused crossings and resume if it's over
	local resumed = {}
	for index, crossing_id in ipairs(SW.sleeping) do
		local rundata = SW.crossings[crossing_id].rundata
		if rundata.sleep <= 0 then
			table.insert(resumed, index)	-- Don't remove while iterating
			SW.do_routine(crossing_id)
		else
			rundata.sleep = rundata.sleep - 1
		end
	end

	-- Remove all the resumed crossings from the sleeping list
	for i = 1, #resumed do
		table.remove(SW.sleeping, i)
	end
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

function SW.crossingClose(crossing_id)
	if SW.update_and_get_trains(crossing_id, 1) == 1 then
		if SW.load_routine(crossing_id, 1) then SW.do_routine(crossing_id) end
	end
end

function SW.crossingOpen(crossing_id)
	if SW.update_and_get_trains(crossing_id, -1) == 0 then
		if SW.load_routine(crossing_id, 2) then SW.do_routine(crossing_id) end
	end
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

SW.init()
---------- SCHRANKENWAERTER ENDE ----------
