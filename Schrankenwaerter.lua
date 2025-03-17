local SW = {
	version = "2.0.0",

	---@type RailroadCrossing[]
	crossings = {},

	---@type (string|integer)[]
	observe = {}
}
local UTILS = {}


-- Crossing Type Definition

---Helper class for setting up a railroad crossing via function-chaining.
---@class CrossingDefiner
---@field save function: 
---@field opening function: 
---@field closing function: 
---@field twice function: 
---@field call_only function: 

---Represents the blueprint of a railroad crossing with user-defined
---functionality. Used exclusively during setup by passing it to the `SW.setup`
---function.
---@class UserCrossing
---@field opening function[]: List of functions to call when opening.
---@field closing function[]: List of functions to call when closing.
---@field twice function[]: List of functions to call for a double-activation.
---@field slot ?integer: ID of an EEP save slot to use for the crossing.

---Represents a railroad crossing.
---@class RailroadCrossing
---@field slot? integer: ID of the EEP save slot for the crossing.
---@field call_only boolean: Whether the crossing opens on road user call only.
---@field sequences function[][]: List of the crossing's sequences.
---@field rundata Rundata: Current state of the crossing.

---Data on a railroad crossing's current state.
---@class Rundata
---@field trains integer: Number of trains currently approaching the crossing.
---@field sleep integer: Number of Lua cycles the crossing is still paused for.
---@field queue integer[]: IDs of the currently-queued sequences.
---@field step integer: ID of the next step to execute in the active sequence.
---@field overall integer: Total number of trains that approached in the active closure.
---@field called integer: Number of road users waiting to cross the call-only crossing.

-- Crossing Config

---Registers a new crossing with the given ID, which can then be configured by
---chaining on the returned crossing object.
---@param id string|number: ID with which to refer to the crossing.
---@return CrossingDefiner: Crossing object.
function SW.define(id)
	SW.crossings[id] = {
		call_only = false,
		slot = nil,
		sequences = { nil, nil, nil },
		rundata = UTILS.new_rundata()
	}
	return {
		call_only = function (self, active)
			if type(active) == "boolean" then
				SW.crossings[id].call_only = active
			end
			return self
		end,
		save = function (self, slot)
			SW.crossings[id].slot = slot

			local rundata = UTILS.load_rundata(slot)
			SW.crossings[id].rundata = rundata

			-- Resume queued sequences
			if #rundata.queue > 0 then table.insert(SW.observe, id) end
			return self
		end,
		opening = function (self, ...)
			SW.crossings[id].sequences[1] = {...}
			return self
		end,
		closing = function (self, ...)
			SW.crossings[id].sequences[2] = {...}
			return self
		end,
		twice = function (self, ...)
			SW.crossings[id].sequences[3] = {...}
			return self
		end,

		-- German function names
		anrufschranke = function(self, aktiv) return self:call_only(aktiv) end,
		speichern = function(self, slot) return self:save(slot) end,
		oeffnen = function(self, ...) return self:opening(...) end,
		schliessen = function(self, ...) return self:closing(...) end,
		doppelt = function(self, ...) return self:twice(...) end
	}
end


-- Crossing Actions

---Pauses a crossing's active sequence for the given number of Lua cycles.
---@param duration integer: Number of Lua cycles to wait.
---@return function: Function that will be called when executing the sequence.
function SW.pause(duration)
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
---@return function: Function that will be called when executing the sequence.
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
---@return function: Function that will be called when executing the sequence.
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
---@return function: Function that will be called when executing the sequence.
function SW.sound(sound_id, turn_on)
	if not EEPStructurePlaySound then return function (_) end end
	return function(_)
		EEPStructurePlaySound(sound_id, turn_on)
		return true
	end
end


-- Main functionality

---The periodically-called heartbeat of the script! Checks all crossings that
---are currently being observed. Ones that are paused have their sleep counter
---reduced by `1`. Others have their sequence queues processed. Crossings which
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
			local finished = UTILS.process_queue(crossing_id)
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
---queues the crossing's closing sequence if no other train is also approaching
---already. If the crossing is already closed but has a double-activation
---sequence defined, that one is queued for the second train to approach. If
---the crossing opens on road user call only, no sequences are queued.
---@param crossing_id integer|string: ID of the target crossing.
function SW.close(crossing_id)
	local crossing = SW.crossings[crossing_id]
	crossing.rundata.overall = crossing.rundata.overall + 1

	if crossing.call_only then
		UTILS.update_and_get_trains(crossing_id, 1)
		return
	end

	if UTILS.update_and_get_trains(crossing_id, 1) == 1 then
		SW.queue_sequence(crossing_id, 2)
		return
	end

	if crossing.sequences[3] ~= nil then
		if crossing.rundata.overall == 2 then
			SW.queue_sequence(crossing_id, 3)
		end
	end
end

---Decreases the trains counter in the given crossing's rundata by `1` and
---queues the crossing's opening sequence if no more trains are approaching.
---If the crossing opens on road user call only, the opening sequence is only
---queued if a road user's call is still being held.
---@param crossing_id integer|string: ID of the target crossing.
function SW.open(crossing_id)
	local crossing = SW.crossings[crossing_id]

	if UTILS.update_and_get_trains(crossing_id, -1) <= 0 then
		crossing.rundata.overall = 0
		if not crossing.call_only or (crossing.rundata.called > 0) then
			SW.queue_sequence(crossing_id, 1)
		end
	end
end

---Registers a request to open the crossing if it only opens on road user call.
---If no trains are approaching the crossing, its opening sequence is queued
---immediately; otherwise, it is queued once no more trains are approaching.
---@param crossing_id integer|string: ID of the target crossing.
function SW.call_request(crossing_id)
	local crossing = SW.crossings[crossing_id]
	if not crossing.call_only then return end

	if UTILS.update_and_get_callers(crossing_id, 1) == 1
			and crossing.rundata.trains == 0 then
		SW.queue_sequence(crossing_id, 1)
	end
end

---Registers that a road user has crossed the target crossing if it only opens
---on road user call. 
---@param crossing_id integer|string: ID of the target crossing.
function SW.call_clear(crossing_id)
	local crossing = SW.crossings[crossing_id]
	if not crossing.call_only then return end

	if UTILS.update_and_get_callers(crossing_id, -1) <= 0 then
		SW.queue_sequence(crossing_id, 2)
	end
end

-- German function names
function SW.definiere(id) return SW.define(id) end
function SW.schliesse(bue_id) SW.close(bue_id) end
function SW.oeffne(bue_id) SW.open(bue_id) end
function SW.anrufen(bue_id) SW.call_request(bue_id) end
function SW.freimelden(bue_id) SW.call_clear(bue_id) end

---Adds the given number to the trains counter of the given crossing and tries
---to save the thusly updated rundata.
---@param crossing_id integer|string: ID of the target crossing.
---@param step 1 | -1: Number to add to the trains counter.
---@return integer: The updated trains counter of the crossing.
function UTILS.update_and_get_trains(crossing_id, step)
	local crossing = SW.crossings[crossing_id]
	crossing.rundata.trains = crossing.rundata.trains + step
	if crossing.rundata.trains < 0 then crossing.rundata.trains = 0 end

	UTILS.save_rundata(crossing_id)

	return crossing.rundata.trains
end

---Adds the given number to the waiting road users counter of the given
---call-only crossing and tries to save the thusly updated rundata.
---@param crossing_id integer|string: ID of the target crossing.
---@param step 1 | -1: Number to add to the waiting road users counter.
---@return integer: The updated waiting road users counter of the crossing.
function UTILS.update_and_get_callers(crossing_id, step)
	local crossing = SW.crossings[crossing_id]
	crossing.rundata.called = crossing.rundata.called + step
	if crossing.rundata.called < 0 then crossing.rundata.called = 0 end

	UTILS.save_rundata(crossing_id)

	return crossing.rundata.called
end

---Works through a crossing's sequence queue.
---
---Until the queue is cleared, the steps of the sequence at queue index `1` are
---executed in order. If the crossing was paused in between, execution is
---resumed at the step after the responsible wait command. If one of the
---executed commands returns `false` (currently just the wait command), the
---process is stopped. Otherwise, sequences are completely worked through one
---after another until the queue is completely cleared.
---@param crossing_id integer|string: ID of the target crossing.
---@return boolean: `true` if the queue got wholly cleared, otherwise `false`.
function UTILS.process_queue(crossing_id)
	local crossing = SW.crossings[crossing_id]
	while #crossing.rundata.queue > 0 do
		local active = crossing.sequences[crossing.rundata.queue[1]]
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

---Adds a sequence to a crossing's sequence queue, also adding the crossing to
---the observation list if necessary.
---@param crossing_id integer|string: ID of the target crossing.
---@param sequence_id integer: ID of the desired sequence.
function SW.queue_sequence(crossing_id, sequence_id)
	table.insert(SW.crossings[crossing_id].rundata.queue, sequence_id)
	UTILS.save_rundata(crossing_id)
	if not UTILS.array_contains(SW.observe, crossing_id) then
		table.insert(SW.observe, crossing_id)
	end
end


-- Saving functionality

---Description of the save format.
local SAVE_FORMAT = {
	version = 1,
	trains = 2,		-- Index of the trains counter.
	sleep = 3,		-- Index of the sleep counter.
	step = 4,		-- Index of the number of the next step to execute.
	queue = 5,		-- Index of the sequence queue items.
	overall = 6,	-- Index of the total current activations tracker.
	called = 7,		-- Index of the call holding indicator.
	delimiter = ",",		-- Char separating the indices.
	delimiter_queue = "-"	-- Char separating the sequence queue items.
}

---Creates `Rundata` with standard values.
---@return Rundata: The created `Rundata`.
function UTILS.new_rundata()
	return {
		queue = {},
		sleep = 0,
		step = 1,
		trains = 0,
		overall = 0,
		called = 0
	}
end

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
				SAVE_FORMAT.delimiter_queue),
		[SAVE_FORMAT.overall] = rundata.overall,
		[SAVE_FORMAT.called] = rundata.called
	}
	EEPSaveData(crossing.slot, table.concat(to_save, SAVE_FORMAT.delimiter))
end

---Tries to load saved rundata. If the `EEPLoadData` function is not available
---or the user hasn't alotted a save slot for the given crossing, the load
---fails, returning standard values. The loaded string is split into its
---components (as determined by the `SAVE_FORMAT`) and returned packed into a
---rundata table.
---@param slot integer: ID of the EEP save slot to load from.
---@return Rundata: The loaded rundata, or standard values if loading failed.
function UTILS.load_rundata(slot)
	local ret = UTILS.new_rundata()
	if not EEPLoadData then return ret end

	local save_exists, saved_data = EEPLoadData(slot)
	if not save_exists then return ret end

	-- Split up the different components of the saved data
	local parts = UTILS.split_string(SAVE_FORMAT.delimiter, saved_data)

	-- Backwards compatibility for v1.0.0, which only saved num of trains
	if #parts == 1 then
		ret.trains = tonumber(parts[1]) or 0
		return ret
	end

	-- Extract the sequence queue from the string segment
	if parts[SAVE_FORMAT.queue] ~= "" then
		local ids = UTILS.split_string(SAVE_FORMAT.delimiter_queue,
				parts[SAVE_FORMAT.queue])
		for index, sequence_id in pairs(ids) do
			ret.queue[index] = tonumber(sequence_id)
		end
	end

	-- Convert everything to numerical values and return it as a rundata table
	ret.trains = tonumber(parts[SAVE_FORMAT.trains]) or 0
	ret.sleep = tonumber(parts[SAVE_FORMAT.sleep]) or 0
	ret.step = tonumber(parts[SAVE_FORMAT.step]) or 1
	ret.overall = tonumber(parts[SAVE_FORMAT.overall]) or 0
	ret.called = tonumber(parts[SAVE_FORMAT.called]) or 0
	return ret
end


-- Utility

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
	table.insert(parts, part)
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
