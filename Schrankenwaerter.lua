local SW = {
	version = "1.0.0",
	sleeping = {},
	crossings = {}
}

-- Crossing Type Definition

---@class RailroadCrossing
---@field slot integer: User-set ID of the EEP save slot for the crossing.
---@field opening function[]: User-set list of functions to call when opening.
---@field closing function[]: User-set list of functions to call when closing.
---@field routines function[][]: (internal) Just contains the opening/closing.
---@field rundata Rundata: (internal) Current state of the crossing.

---Data on a railroad crossing's current state.
---@class Rundata
---@field trains integer: Number of trains currently approaching the crossing.
---@field sleep integer: Number of Lua cycles the crossing is still paused for.
---@field routine function[]: Functions left to call in the active routine.

-- Crossing Actions

---Pauses a crossing's routine for the given number of Lua cycles.
---@param duration integer: Number of Lua cycles to wait.
---@return function: Function that will be called when executing the routine.
function SW.wait(duration)
	return function(crossing_id)
		SW.crossings[crossing_id].rundata.sleep = duration
		table.insert(SW.sleeping, crossing_id)
		return false
	end
end

---Set the given signal to the given position.
---@param signal_id integer: ID of the target signal.
---@param position integer: ID of the position to set the signal to.
---@return function: Function that will be called when executing the routine.
function SW.signal(signal_id, position)
	if not EEPSetSignal then return function (_) end end
	return function(_)
		EEPSetSignal(signal_id, position)
		return true
	end
end

---Move an axis on a structure.
---@param immo_id string: Lua name of the target structure.
---@param axis string: Name of the axis to move on the structure.
---@param step integer: Number of steps to move the axis.
---@return function: Function that will be called when executing the routine.
function SW.immo(immo_id, axis, step)
	if not EEPStructureAnimateAxis then return function (_) end end
	return function(_)
		EEPStructureAnimateAxis(immo_id, axis, step)
		return true
	end
end

---Turns a given sound on or off.
---@param sound_id string: Lua name of the target sound.
---@param turn_on boolean: `true` to turn the sound on, `false` to turn it off.
---@return function: Function that will be called when executing the routine.
function SW.sound(sound_id, turn_on)
	if not EEPStructurePlaySound then return function (_) end end
	return function(_)
		EEPStructurePlaySound(sound_id, turn_on)
		return true
	end
end

---Initializes the script with the given set of railroad crossing definitions,
---attaching the required rundata to each.
---@param ... RailroadCrossing[]: List of crossings to manage.
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
		if crossing.slot ~= nil and EEPLoadData then
			local save_exists, saved_trains = EEPLoadData(crossing.slot)
			if save_exists then crossing.rundata.trains = saved_trains end
		end
	end
	print("Schrankenwaerter ", SW.version, " set up!")
end

-- Execution

---Provides the pausing functionality for railroad crossings. Each currently
---paused crossing has the sleep counter in their rundata decreased by `1`, and
---those which thus reach a sleep of `0` resume their paused routine.
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

---Increases the trains counter in the given crossing's rundata by 1 and calls
---the crossing's closing routine if no other train is also approaching.
---@param crossing_id integer|string: ID of the target crossing.
function SW.crossingClose(crossing_id)
	if SW.update_and_get_trains(crossing_id, 1) > 1 then return end
	if SW.load_routine(crossing_id, 1) then SW.do_routine(crossing_id) end
end

---Decreases the trains counter in the given crossing's rundata by 1 and calls
---the crossing's opening routine if no more trains are approaching.
---@param crossing_id integer|string: ID of the target crossing.
function SW.crossingOpen(crossing_id)
	if SW.update_and_get_trains(crossing_id, -1) > 0 then return end
	if SW.load_routine(crossing_id, 2) then SW.do_routine(crossing_id) end
end

---Adds the given number to the trains counter of the given crossing's rundata
---and saves the thusly updated counter, if an EEP save slot has been alotted
---to the crossing by the user.
---@param crossing_id integer|string: ID of the target crossing.
---@param step 1 | -1: Number to add to the trains counter.
---@return integer: The updated trains counter of the crossing.
function SW.update_and_get_trains(crossing_id, step)
	local crossing = SW.crossings[crossing_id]
	crossing.rundata.trains = crossing.rundata.trains + step
	if crossing.rundata.trains < 0 then crossing.rundata.trains = 0 end

	if crossing.slot ~= nil and EEPSaveData then
		EEPSaveData(crossing.slot, crossing.rundata.trains)
	end

	return crossing.rundata.trains
end

---Loads the given routine into the given crossing's routine rundata.
---@param crossing_id integer|string: ID of the target crossing.
---@param routine_id integer: ID of the target routine.
---@return boolean `true` if loaded successfully, otherwise `false`.
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

---Calls all functions listed in the given crossing's rundata routine,
---ceasing execution if either one of the called functions returns `false`
---(like the `SW.wait` command) or all functions have been called.
---@param crossing_id integer|string: ID of the target crossing.
function SW.do_routine(crossing_id)
	local routine = SW.crossings[crossing_id].rundata.routine
	while #routine > 0 do
		local continue = routine[1](crossing_id)
		table.remove(routine, 1)
		if not continue then break end
	end
end

return SW
