clearlog()

function EEPMain()
	SW.main()
	return 1
end

-- Einbindung des Skripts und Definieren einiger BÜs
-- Integrating the script and defining a couple of crossings
SW = require("Schrankenwaerter")
SW.setup({

	-- Einfacher BÜ aus zwei Signalen
	-- Simple crossing consisting of two signals
	["simple"] = {
		closing = {
			SW.signal(1, 2),	-- Signal 1 auf Stellung 2 (= i.d.R. "Halt")
			SW.signal(2, 2)		-- Signal 2 to position 2 (= "stop", usually)
		},
		opening = {
			SW.signal(1, 1),	-- Signal 1 auf Stellung 1 (= i.d.R. "Fahrt")
			SW.signal(2, 1)		-- Signal 2 to position 1 (="go", usually)
		}
	},

	-- Lichtzeichen und Schranken als separate Signale
	-- Lights and barriers as separate signals
	["separate_signals"] = {
		closing = {
			-- Benutzen Sie einen wait-Befehl am Anfang der closing-Routine, um
			-- ein "Zucken" der Schranken zu vermeiden, wenn innerhalb des
			-- Öffnungsvorganges ein neuer Zug den BÜ schließt.
			-- Use a wait command at the beginning of the closing routine to
			-- avoid the barriers "twitching" when a new train closes the
			-- crossing while it is still opening.
			SW.wait(15),
			SW.signal(1, 2),	-- Zuerst wird das Lichtzeichen geschaltet
			SW.signal(2, 2),	-- First, the lights are set
			SW.wait(25),		-- Warte 5 Sekunden // wait 5 seconds
			SW.signal(3, 2),	-- Danach werden die Schranken geschlossen
			SW.signal(4, 2)		-- Thereafter, the barriers are closed
		},
		opening = {
			SW.signal(3, 1),
			SW.signal(4, 1),
			SW.wait(10),
			SW.signal(1, 1),
			SW.signal(2, 1)
		}
	},

	-- Zweiphasige Signale plus Immobilien (hier: Shop-Set V80NJS20083)
	-- Two-phase signals plus structures (here: shop set V80NJS20083)
	["wssb"] = {
		closing = {
			SW.wait(50),
			SW.signal(1, 2),
			SW.signal(2, 2),
			SW.immo("#1_WSSB_Andreaskreuz2", "Licht", 100),
			SW.immo("#2_WSSB_Andreaskreuz2", "Licht", 100),
			SW.immo("#1_WSSB_Andreaskreuz2", "Sound", 100),
			SW.immo("#2_WSSB_Andreaskreuz2", "Sound", 100),
			SW.wait(25),
			SW.signal(1, 3),
			SW.signal(2, 3),
			SW.wait(40),
			SW.immo("#1_WSSB_Andreaskreuz2", "Sound", -100),
			SW.immo("#2_WSSB_Andreaskreuz2", "Sound", -100),
		},
		opening = {
			SW.signal(1, 2),
			SW.signal(2, 2),
			SW.wait(40),
			SW.signal(1, 1),
			SW.signal(2, 1),
			SW.immo("#1_WSSB_Andreaskreuz2", "Licht", -100),
			SW.immo("#2_WSSB_Andreaskreuz2", "Licht", -100),
		}
	},
})

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
