local SW = {
	version = "1.1.0",
	crossings = {},
	observe = {}
}
local UTILS = {}


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
---@field queue integer[]: IDs of the currently-queued routines.
---@field step integer: ID of the next step to execute in the active routine.

-- Crossing Actions

---Pauses a crossing's active routine for the given number of Lua cycles.
---@param duration integer: Number of Lua cycles to wait.
---@return function: Function that will be called when executing the routine.
function SW.wait(duration)
	return function(crossing_id)
		SW.crossings[crossing_id].rundata.sleep = duration
		if not UTILS.array_contains(SW.observe, crossing_id) then
			table.insert(SW.observe, crossing_id)
		end
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
---attaching the required rundata to each. If possible, any rundata saved for
---the crossing is loaded.
---@param ... RailroadCrossing[]: List of crossings to manage.
function SW.setup(...)
	SW.crossings = ...
	for id, crossing in pairs(SW.crossings) do
		-- Make routines accessible by index number
		crossing.routines = { crossing.closing, crossing.opening }

		crossing.rundata = UTILS.load_rundata(id)
		if #crossing.rundata.queue > 0 then	-- Resume queued routines
			table.insert(SW.observe, id)
		end
	end
	print("Schrankenwaerter ", SW.version, " set up!")
end

---The periodically-called heartbeat of the script! Checks all crossings that
---are currently being observed. Ones that are paused have their sleep counter
---reduced by `1`. Others have their routine queues processed. Crossings which
---have worked off their whole queue and aren't sleeping anymore are removed
---from the list of observed crossings.
function SW.main()
	-- Record the crossings due for removal from the observe list first, so
	-- they aren't removed while iterating it.
	local to_remove = {}
	for index, crossing_id in pairs(SW.observe) do
		local rundata = SW.crossings[crossing_id].rundata
		if rundata.sleep > 0 then
			rundata.sleep = rundata.sleep - 1
		elseif #rundata.queue > 0 then
			local finished = SW.process_queue(crossing_id)
			if finished then table.insert(to_remove, index) end
		else
			table.insert(to_remove, index)
		end
		UTILS.save_rundata(crossing_id)
	end

	for _, observe_index in pairs(to_remove) do
		table.remove(SW.observe, observe_index)
	end
end

---Increases the trains counter in the given crossing's rundata by `1` and
---calls the crossing's closing routine if no other train is also approaching.
---@param crossing_id integer|string: ID of the target crossing.
function SW.close(crossing_id)
	if SW.update_and_get_trains(crossing_id, 1) > 1 then return end

	SW.queue_routine(crossing_id, 1)
	if not UTILS.array_contains(SW.observe, crossing_id) then
		table.insert(SW.observe, crossing_id)
	end
end

---Decreases the trains counter in the given crossing's rundata by `1` and
---calls the crossing's opening routine if no more trains are approaching.
---@param crossing_id integer|string: ID of the target crossing.
function SW.open(crossing_id)
	if SW.update_and_get_trains(crossing_id, -1) > 0 then return end

	SW.queue_routine(crossing_id, 2)
	if not UTILS.array_contains(SW.observe, crossing_id) then
		table.insert(SW.observe, crossing_id)
	end
end

-- Backwards compatibility for v1.0.0
function SW.crossingClose(crossing_id) SW.close(crossing_id) end
function SW.crossingOpen(crossing_id) SW.open(crossing_id) end

---Adds the given number to the trains counter of the given crossing and tries
---to save the thusly updated rundata.
---@param crossing_id integer|string: ID of the target crossing.
---@param step 1 | -1: Number to add to the trains counter.
---@return integer: The updated trains counter of the crossing.
function SW.update_and_get_trains(crossing_id, step)
	local crossing = SW.crossings[crossing_id]
	crossing.rundata.trains = crossing.rundata.trains + step
	if crossing.rundata.trains < 0 then crossing.rundata.trains = 0 end

	UTILS.save_rundata(crossing_id)

	return crossing.rundata.trains
end

---Adds a routine to a crossing's routine queue.
---@param crossing_id integer|string: ID of the target crossing.
---@param routine_id integer: ID of the desired routine.
function SW.queue_routine(crossing_id, routine_id)
	table.insert(SW.crossings[crossing_id].rundata.queue, routine_id)
	UTILS.save_rundata(crossing_id)
end

---Works through a crossing's routine queue.
---
---Until the queue is cleared, the steps of the routine at queue index `1` are
---executed in order. If the crossing was paused in between, execution is
---resumed at the step after the responsible wait command. If one of the
---executed commands returns `false` (currently just the wait command), the
---process is stopped. Otherwise, routines are completely worked through one
---after another until the queue is completely cleared.
---@param crossing_id integer|string: ID of the target crossing.
---@return boolean: `true` if the queue got wholly cleared, otherwise `false`.
function SW.process_queue(crossing_id)
	local crossing = SW.crossings[crossing_id]
	while #crossing.rundata.queue > 0 do
		local active = crossing.routines[crossing.rundata.queue[1]]
		for i = crossing.rundata.step, #active do
			crossing.rundata.step = i + 1
			if i == #active then
				table.remove(crossing.rundata.queue, 1)
				crossing.rundata.step = 1
			end

			local continue = active[i](crossing_id)
			if not continue then return false end
		end
	end
	return true
end

---Description of the save format.
local SAVE_FORMAT = {
	version = 1,
	trains = 2,	-- Index of the trains counter.
	sleep = 3,	-- Index of the sleep counter.
	step = 4,	-- Index of the number of the next step to execute.
	queue = 5,	-- Index of the routine queue items.
	delimiter = ",",		-- Char separating the indices.
	delimiter_queue = "-"	-- Char separating the routine queue items.
}

---Tries to save a crossing's current rundata. If the `EEPSaveData` function is
---not available or the user hasn't alotted a save slot for the given crossing,
---the save fails. The different components of the data saved are formatted
---according to the `SAVE_FORMAT`.
---@param crossing_id integer|string: ID of the target crossing.
function UTILS.save_rundata(crossing_id)
	local crossing = SW.crossings[crossing_id]
	if crossing.slot == nil or not EEPSaveData then return end

	local rundata = crossing.rundata
	local to_save = {
		[SAVE_FORMAT.version] = SW.version,
		[SAVE_FORMAT.trains] = rundata.trains,
		[SAVE_FORMAT.sleep] = rundata.sleep,
		[SAVE_FORMAT.step] = rundata.step,
		[SAVE_FORMAT.queue] = table.concat(rundata.queue,
				SAVE_FORMAT.delimiter_queue)
	}
	EEPSaveData(crossing.slot, table.concat(to_save, SAVE_FORMAT.delimiter))
end

---Tries to load a crossing's saved rundata. If the `EEPLoadData` function is
---not available or the user hasn't alotted a save slot for the given crossing,
---the load fails, returning standard values. The loaded string is split into
---its components (as determined by the `SAVE_FORMAT`) and returned packed into
---a rundata table.
---@param crossing_id integer|string: ID of the target crossing.
---@return Rundata: The loaded rundata, or standard values if loading failed.
function UTILS.load_rundata(crossing_id)
	local crossing = SW.crossings[crossing_id]
	if crossing.slot == nil or not EEPLoadData then
		return {
			queue = {},
			sleep = 0,
			step = 1,
			trains = 0
		}
	end

	-- Split up the different components of the saved data
	local parts = UTILS.split_string(SAVE_FORMAT.delimiter,
			select(-1, EEPLoadData(crossing.slot)))

	-- Backwards compatibility for v1.0.0, which only saved num of trains
	if #parts == 1 then
		return {
			trains = tonumber(parts[1]) or 0,
			sleep = 0,
			step = 1,
			queue = {}
		}
	end

	-- Extract the routine queue from the string segment
	local queue = {}
	if parts[SAVE_FORMAT.queue] ~= "" then
		local ids = UTILS.split_string(SAVE_FORMAT.delimiter_queue,
				parts[SAVE_FORMAT.queue])
		for index, routine_id in pairs(ids) do
			queue[index] = tonumber(routine_id)
		end
	end

	-- Convert everything to numerical values and return it as a rundata table
	return {
		trains = tonumber(parts[SAVE_FORMAT.trains]) or 0,
		sleep = tonumber(parts[SAVE_FORMAT.sleep]) or 0,
		step = tonumber(parts[SAVE_FORMAT.step]) or 1,
		queue = queue
	}
end

---Utility function for splitting a string at the given delimiting character.
---@param delimiter string: The **single** character to split at.
---@param to_split string: The string to split.
---@return table<integer, string>: The substrings the string was split into.
function UTILS.split_string(delimiter, to_split)
	to_split = tostring(to_split)
	local parts = {}
	local part = ""
	for i = 1, #to_split do
		local letter = to_split:sub(i, i)
		if letter == delimiter then
			table.insert(parts, part)
			part = ""
		else
			part = part..letter
		end
	end
	if #part > 0 then table.insert(parts, part) end
	return parts
end

---Utility function for checking whether an array contains a specific item.
---@param array table<integer, any>: The array to search.
---@param search any: The item to look for.
---@return boolean: `true` if the item was found, otherwise `false`.
function UTILS.array_contains(array, search)
	for _, value in ipairs(array) do
		if value == search then return true end
	end
	return false
end

return SW
