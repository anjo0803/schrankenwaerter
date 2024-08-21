# schrankenwaerter
> [🇩🇪](#deutsch) // [🇬🇧](#english)

## Deutsch
Der **Schrankenwärter** ist ein Lua-Skript zur Steuerung von Bahnübergängen im
Eisenbahnsimulator EEP - vom einfachen BÜ mit zwei Schranken bis hin zu
komplexen Systemen aus vielen separaten Lichtzeichen, Schranken, Immobilien und
Sounds samt Zeitpuffern dazwischen!

### Einbinden des Skripts
Um das Schrankenwärter-Skript in Ihre Anlage einzubinden, kopieren Sie bitte
zunächst die Datei 
[`schrankenwaerter.lua`](https://github.com/anjo0803/schrankenwaerter/blob/master/schrankenwaerter.lua)
in den "LUA"-Ordner ihrer EEP-Installation, sodass diese für alle Anlagen
sichtbar ist. Im Lua-Skript Ihrer Anlagen können Sie das Schrankenwärter-Skript
dann mittels der Lua-Funktion `require` aktivieren:
```lua
SW = require("schrankenwaerter")
```
Fügen Sie bitte außerdem einen Aufruf der Funktion `SW.main()` in ihre
`EEPMain()`-Funktion ein, damit der `SW.wait`-Befehl korrekt funktioniert:
```lua
function EEPMain()
	SW.main()
	return 1
end
```

### Konfigurieren eines BÜs
Ihre Bahnübergänge können Sie nach Aktivierung des Schrankenwärter-Skripts mit
der Funktion `SW.setup` definieren:
```lua
SW = require("schrankenwaerter")
SW.setup({
	-- Liste Ihrer BÜs hier!
})
```

#### Datenstruktur
Damit das Skript Ihre BÜs korrekt handhaben kann, müssen diese in der folgenden
Struktur beschrieben werden:
```lua
[ID] = {
	slot = 1,
	closing = {
		-- Hierzu gleich mehr unter "Befehle"
	},
	opening = {
		-- Hierzu gleich mehr unter "Befehle"
	}
}
```
Das Feld "slot" ist dabei optional: Sie können darin dem BÜ einen der
EEPSaveData-Slots zuweisen. Dieser wird dann genutzt, um die Anzahl der Züge zu
speichern, die den BÜ momentan befahren, sodass diese Daten nicht beim Neuladen
des Skripts oder der Anlage verloren gehen. Die `ID` können Sie beliebig wählen
(bspw `"bue_beispielstr"` oder einfach numerisch `1`) oder auch auslassen - in
diesem Fall wird der entsprechende BÜ von Lua automatisch numerisch indexiert.

#### Befehle
Die BÜ-Steuerung des Schrankenwärter-Skripts erfolgt durch "Befehle". Den
Schließungs- und Öffnungsvorgängen ist dabei jeweils eine Liste an Befehlen
zugeordnet, die nacheinander ausgeführt werden. Dies kann beispielsweise der
Befehl sein, ein bestimmtes Signal in eine definierte Stellung zu bringen oder
einen Sound ein- oder auszuschalten.

Momentan werden folgende Befehle vom Skript selbst bereitgestellt:
| Name | Effekt | Parameter |
|-|-|-|
| `SW.signal(signal_id, stellung)` | Setzt ein Signal in eine Stellung. | `signal_id`: ID des Signals, das gesetzt werden soll.<br>`stellung`: ID der Stellung, in die das Signal gesetzt werden soll. |
| `SW.immo(immo_id, achse, schritte)` | Bewegt eine Achse an einer Immobilie. | `immo_id`: Lua-Name der Ziel-Immobilie.<br>`achse`: Name der zu bewegenden Achse.<br>`schritte`: Anzahl der Schritte, die die Achse bewegt werden soll. |
| `SW.sound(sound_id, anschalten)` | Schaltet einen Sound an oder aus. | `sound_id`: Lua-Name des Ziel-Sounds.<br>`anschalten`: `true`, um den Sound anzuschalten; `false`, um ihn auszuschalten. |
| `SW.wait(zyklen)` | Pausiert die Befehlsausführung. | `zyklen`: Anzahl der Lua-Zyklen, für die die Ausführung ruhen soll. Ein Zyklus entspricht einem Aufruf der `SW.main()`-Funktion, d.h. wenn diese in jedem Aufruf der `EEPMain()`-Funktion aufgerufen wird, dauert jeder Zyklus 200ms. |

#### Beispiele
```lua
-- Einfacher BÜ aus zwei Signalen
-- Simple crossing consisting of two signals
{
	closing = {
		SW.signal(1, 2),	-- Signal 1 auf Stellung 2 (= i.d.R. "Halt")
		SW.signal(2, 2)		-- Signal 2 to position 2 (= "stop", usually)
	},
	opening = {
		SW.signal(1, 1),	-- Signal 1 auf Stellung 1 (= i.d.R. "Fahrt")
		SW.signal(2, 1)		-- Signal 2 to position 1 (="go", usually)
	}
}

-- BÜ mit Lichtzeichen und Schranken als separaten Signalen
-- Crossing with lights and barriers as separate Signals
{
	closing = {
		SW.signal(1, 2),	-- Zuerst wird das Lichtzeichen gesetzt
		SW.signal(2, 2),	-- First, the lights are set
		SW.wait(25),		-- Warte 5 Sekunden // wait 5 seconds
		SW.signal(3, 2),	-- Danach werden die Schranken gesetzt
		SW.signal(4, 2)		-- Thereafter, the barriers are set
	},
	opening = {
		SW.signal(3, 1),
		SW.signal(4, 1),
		SW.wait(10),
		SW.signal(1, 1),
		SW.signal(2, 1)
	}
}
```

### Kontaktpunkte
Nachdem die gewünschten BÜs definiert wurden, sind natürlich noch entsprechende
Kontaktpunkte zu erstellen. Darin haben Sie für die aufzurufende Lua-Funktion
zwei Möglichkeiten:

- Mittels "Bennys Codezeile" sollte es möglich sein, das Schrankenwärter-Skript
  direkt aufzurufen, indem Sie `SW.crossingClose(bue_id)` eintragen (und
  `bue_id` durch die von Ihnen für den BÜ gewählte `ID` ersetzen).
- Alternativ können Sie selbstverständlich eine eigene Funktion definieren, die
  dann ihrerseits `SW.crossingClose(bue_id)` aufruft, und diese eintragen.

Für den BÜ wieder freigebende Kontaktpunkte muss nur sinngemäß die Funktion
`SW.crossingOpen(bue_id)` aufgerufen werden.

### Lizenz
[Gemeinfrei kraft der Unlicense.](https://github.com/anjo0803/schrankenwaerter/blob/master/UNLICENSE.txt)

## English
The **Schrankenwaerter** is a Lua script for controlling railroad crossings in
the train simulator EEP - from a simple crossing of just two signals to complex
setups of many separate lights, barriers, structures, and sounds plus time
buffers in between!

### Using the script
To use the Schrankenwaerter script in your railroad system, please first copy
the file
[`schrankenwaerter.lua`](https://github.com/anjo0803/schrankenwaerter/blob/master/schrankenwaerter.lua)
to the "LUA" folder in the root of your EEP installation. You can then activate
it in the Lua script of any railroad system using the Lua `require` function:
```lua
SW = require("schrankenwaerter")
```

 simply copy the
file contents of `schrankenwaerter.lua` to your system's lua script.

Please also add a call to the `SW.main()` function into your `EEPMain()`
function in order for the `SW.wait` command to function properly:
```lua
function EEPMain()
	SW.main()
	return 1
end
```

### Crossing setup
After activating the Schrankenwaerter script, you can define your railroad
crossings using the `SW.setup` function:
```lua
SW = require("schrankenwaerter")
SW.setup({
	-- List of your railroad crossings here!
})
```

#### Data structure
In order for the script to correctly manage your crossings, they must be
described in the following structure:
```lua
[ID] = {
	name = "My Crossing",
	slot = 1,
	closing = {
		-- Will be detailed below in "Commands"
	},
	opening = {
		-- Will be detailed below in "Commands"
	}
}
```
The "slot" field is optional: Within it, you may assign one of the EEPSaveData
slots to the crossing. This will then be used to save the number of trains
currently approaching the crossing, so that data isn't lost during reloads of
the script or your whole railway system. You are also free to choose the `ID`
(e.g. `"crossing_example_st"` or just numerically `1`) or leave it out
entirely, in which case Lua will automatically index it numerically.

#### Commands
Crossings are controlled by the Schrankenwaerter script via "commands". A list
of commands to be executed one after another is assigned to the opening and
closing sequences respectively. Commands may be to set a given signal to a
defined position, or to turn a given sound on or off.

Currently, the script itself provides the following commands:
| Name | Effect | Parameters |
|-|-|-|
| `SW.signal(signal_id, position)` | Set a signal. | `signal_id`: ID of the target signal.<br>`position`: ID of the position that the signal should be set to. |
| `SW.immo(immo_id, axis, steps)` | Moves an axis on a structure. | `immo_id`: Lua name of the target structure.<br>`axis`: Name of the axis to move.<br>`steps`: Number of steps to move the axis. |
| `SW.sound(sound_id, turn_on)` | Turns a sound on or off. | `sound_id`: Lua name of the target sound.<br>`turn_on`: `true` to turn on the sound; `false` to turn it off. |
| `SW.wait(cycles)` | Pauses execution of commands. | `cycles`: Number of Lua cycles to pause. One cycle is equivalent to one call of the `SW.main()` function, so if it is called with every call of the `EEPMain()` function, one cycle is 200ms. |

#### Examples
You can find example configurations [here](#beispiele).

### Contact points
Naturally, contact points corresponding to the defined railroad crossings still
need to be set up after. There are two possibilities for the Lua function to
call therein:

- Using "Benny's Code Line", it should be possible to call the Schrankenwaerter
  script directly via `SW.crossingClose(crossing_id)` (replacing `crossing_id`
  with the `ID` you chose for the crossing).
- Alternatively, you naturally can just define another function, which itself
  calls `SW.crossingClose(crossing_id)`, and use that.

In contact points that should open the crossing, simply call the
`SW.crossingOpen(crossing_id)` function instead.

### Licence
[Public domain (via the Unlicense).](https://github.com/anjo0803/schrankenwaerter/blob/master/UNLICENSE.txt)
