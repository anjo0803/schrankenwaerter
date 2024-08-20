# schrankenwaerter
> [🇩🇪](#deutsch) // [🇬🇧](#english)

## Deutsch
Der **Schrankenwärter** ist ein Lua-Skript zur Steuerung von Bahnübergängen im
Eisenbahnsimulator EEP - vom einfachen BÜ mit zwei Schranken bis hin zu
komplexen Systemen aus vielen separaten Lichtzeichen, Schranken, Immobilien und
Sounds samt Zeitpuffern dazwischen!

### Einbinden des Skripts
Um das Schrankenwärter-Skript in Ihre Anlage einzubinden, kopieren Sie einfach
den Inhalt der Datei `schrankenwaerter.lua` in das Lua-Skript Ihrer Anlage. Zur
einfachen späteren Identifizierung befindet sich das komplette
Schrankenwärter-Skript zwischen den beiden Kommentar-Blöcken "SCHRANKENWAERTER
START" und "SCHRANKENWAERTER ENDE".

### Einrichten eines BÜs
Ihre Bahnübergänge können Sie innerhalb des `return`-Werts der Funktion
`SW.CROSSING_CONFIG` am Anfang des Schrankenwärter-Skripts beschreiben. Im
Skript selbst weist ein weiterer Kommentar die richtige Stelle aus.

#### Datenstruktur
Damit das Skript Ihren BÜ korrekt handhaben kann, muss dieser in der folgenden
Struktur beschrieben werden:
```lua
{
	name = "Mein BÜ",
	slot = 1,
	closing = {
		-- Hierzu gleich mehr unter "Befehle"
	},
	opening = {
		-- Hierzu gleich mehr unter "Befehle"
	}
}
```
Das Feld "name" ist optional und dient lediglich dazu, dass Sie dem BÜ bei
Bedarf zur leichteren Identifizierbarkeit im Code einen eigenen Namen geben
können. Auch das Feld "slot" ist optional: Sie können darin dem BÜ einen der
EEPSaveSlots zuweisen. Dieser wird dann genutzt, um die Anzahl der Züge zu
speichern, die den BÜ momentan befahren, sodass diese Daten nicht beim Neuladen
des Skripts oder der Anlage verloren gehen.

**WICHTIG:** Alle BÜs, auch wenn nur ein einziger BÜ definiert wird, müssen
jeweils innerhalb eigener geschweiften Klammern, d.h. nicht *direkt* innerhalb
derer der `SW.CROSSING_CONFIG`-Funktion, beschrieben werden:
```lua
function SW.CROSSING_CONFIG() return {
	{
		closing = { },
		opening = { }
	},
	-- Weitere BÜs können dann einfach angereiht werden
}
```

#### Befehle
Die BÜ-Steuerung des Schrankenwärter-Skripts erfolgt durch "Befehle". Dem
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

### Lizenz
[Gemeinfrei kraft der Unlicense.](https://github.com/anjo0803/schrankenwaerter/blob/master/UNLICENSE.txt)

## English
The **Schrankenwaerter** is a Lua script for controlling railroad crossings in
the train simulator EEP - from a simple crossing of just two signals to complex
setups of many separate lights, barriers, structures, and sounds plus time
buffers in between!

### Using the script
To use the Schrankenwaerter script in your railroad system, simply copy the
file contents of `schrankenwaerter.lua` to your system's lua script. For easy
identification of the Schrankenwaerter script later on, its entirety is
contained between the two comment blocks "SCHRANKENWAERTER START" and
"SCHRANKENWAERTER ENDE".

### Crossing setup
You may describe your railroad crossings within the `return` value of the
`SW.CROSSING_CONFIG` function at the top of the Schrankenwaerter script. The
correct spot is also marked by a comment within the script itself.

#### Data structure
In order for the script to correctly manage your crossing, it must be
described in the following structure:
```lua
{
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
The field "name" is optional and only serves to help you in identifying a
crossing in the script more easily by naming it. The "slot" field likewise is
optional: Within it, you may assign one of the EEPSaveSlots to the crossing.
This will then be used to save the number of trains currently approaching the
crossing, so that data isn't lost during reloads of the script or your whole
railway system.

**IMPORTANT:** All crossings, even if only a single crossing is registered, have
to be set up within their own curly braces - that is, not *directly* within
those enclosing the `SW.CROSSING_CONFIG` function's return value:
```lua
function SW.CROSSING_CONFIG() return {
	{
		closing = { },
		opening = { }
	},
	-- More crossings can then be appended here
}
```

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

### Licence
[Public domain (via the Unlicense).](https://github.com/anjo0803/schrankenwaerter/blob/master/UNLICENSE.txt)
