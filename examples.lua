clearlog()

function EEPMain()
	SW.main()	-- Für SW.wait-Befehl benötigt // Required for SW.wait command!
    return 1
end

-- Einbindung des Skripts und Definieren einiger BÜs
-- Integrating the script and defining a couple of crossings
SW = require("schrankenwaerter")
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
})

--[[
Es folgen jeweils eine eigene Funktion zum An- und Abmelden von Zügen an jedem
BÜ, die in den entsprechenden Kontaktpunkten aufgerufen werden sollen. Mittels
"Bennys Codezeile" können in dem jeweiligen Kontaktpunkt aber auch die
Funktionen SW.crossingClose bzw. SW.crossingOpen direkt mit der relevanten
BÜ-ID aufgerufen werden.

The following are dedicated functions to register and de-register trains
approaching each crossing, which should be called in the relevant contact
points. Using "Benny's Code Line", the functions SW.crossingClose and
SW.crossingOpen can be called with the relevant crossing ID in the contact
points directly.
]]

function approach_simple()
	SW.crossingClose("simple")
end

function pass_simple()
	SW.crossingOpen("simple")
end

function announce_separate()
	SW.crossingClose("separate_signals")
end

function pass_separate()
	SW.crossingOpen("separate_signals")
end
