clearlog()

function EEPMain()
	SW.main()
	return 1
end

-- Einbindung des Skripts und Definieren einiger BÜs
-- Integrating the script and defining a couple of crossings
SW = require("Schrankenwaerter")

-- Einfacher BÜ aus zwei Signalen
-- Simple crossing consisting of two signals
SW.define("simple")
	:closing(
		SW.signal(1, 2),	-- Signal 1 auf Stellung 2 (= i.d.R. "Halt")
		SW.signal(2, 2)		-- Signal 2 to position 2 (= "stop", usually)
	)
	:opening(
		SW.signal(1, 1),	-- Signal 1 auf Stellung 1 (= i.d.R. "Fahrt")
		SW.signal(2, 1)		-- Signal 2 to position 1 (="go", usually)
	)

-- Lichtzeichen und Schranken als separate Signale
-- Lights and barriers as separate signals
SW.define("separate_signals")
	:save(1)	-- Zuweisen eines Save-Slots // Assigning a save slot
	:closing(
		-- Benutzen Sie einen pause-Befehl am Anfang der Schließroutine, um
		-- eine Mindestgrünzeit zu etablieren. So wird bspw. auch ein "Zucken"
		-- der Schranken zu vermieden, wenn innerhalb des Öffnungsvorganges ein
		-- neuer Zug den BÜ schließt.
		-- Use a pause command at the beginning of the closing routine to
		-- establish a minimum time the crossing stays open. This also avoids
		-- the barriers "twitching" when a new train closes the crossing while
		-- it is still opening.
		SW.pause(15),
		SW.signal(1, 2),	-- Zuerst wird das Lichtzeichen geschaltet
		SW.signal(2, 2),	-- First, the lights are set
		SW.pause(25),		-- Warte 5 Sekunden // wait 5 seconds
		SW.signal(3, 2),	-- Danach werden die Schranken geschlossen
		SW.signal(4, 2)		-- Thereafter, the barriers are closed
	)
	:opening(
		SW.signal(3, 1),
		SW.signal(4, 1),
		SW.pause(10),
		SW.signal(1, 1),
		SW.signal(2, 1)
	)

-- Zweiphasige Signale, Immobilien, Reversieren (hier: Shop-Set V80NJS20083)
-- Two-phase signals, structures, reversing (here: shop set V80NJS20083)
SW.define("wssb")
	:save(2)
	:closing(
		SW.pause(50),
		SW.signal(1, 2),
		SW.signal(2, 2),
		SW.immo("#1_WSSB_Andreaskreuz2", "Licht", 100),
		SW.immo("#2_WSSB_Andreaskreuz2", "Licht", 100),
		SW.immo("#1_WSSB_Andreaskreuz2", "Sound", 100),
		SW.immo("#2_WSSB_Andreaskreuz2", "Sound", 100),
		SW.pause(25),
		SW.signal(1, 3),
		SW.signal(2, 3),
		SW.pause(40),
		SW.immo("#1_WSSB_Andreaskreuz2", "Sound", -100),
		SW.immo("#2_WSSB_Andreaskreuz2", "Sound", -100)
	)
	:opening(
		SW.signal(1, 2),
		SW.signal(2, 2),
		SW.pause(40),
		SW.signal(1, 1),
		SW.signal(2, 1),
		SW.immo("#1_WSSB_Andreaskreuz2", "Licht", -100),
		SW.immo("#2_WSSB_Andreaskreuz2", "Licht", -100)
	)
	:reverse(
		SW.signal(1, 3),
		SW.signal(2, 3)
	)

--[[
Es folgen jeweils eine eigene Funktion zum An- und Abmelden von Zügen an jedem
BÜ, die in den entsprechenden Kontaktpunkten aufgerufen werden sollen. Mittels
"BetterContacts" können in dem jeweiligen Kontaktpunkt aber auch die Funktionen
SW.crossingClose bzw. SW.crossingOpen direkt mit der relevanten BÜ-ID
aufgerufen werden.

The following are dedicated functions to register and de-register trains
approaching each crossing, which should be called in the relevant contact
points. Using "BetterContacts", the functions SW.crossingClose and
SW.crossingOpen can be called with the relevant crossing ID in the contact
points directly.
]]

function approach_simple()
	SW.close("simple")
end

function pass_simple()
	SW.open("simple")
end

function approach_separate()
	SW.close("separate_signals")
end

function pass_separate()
	SW.open("separate_signals")
end

function approach_wssb()
	SW.close("wssb")
end

function pass_wssb()
	SW.open("wssb")
end
