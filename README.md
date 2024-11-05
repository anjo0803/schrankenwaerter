[![Installer](https://github.com/anjo0803/schrankenwaerter/actions/workflows/install.yml/badge.svg)](https://github.com/anjo0803/schrankenwaerter/releases/latest)
[![Version](https://img.shields.io/github/v/release/anjo0803/schrankenwaerter)](https://github.com/anjo0803/schrankenwaerter/releases/latest)
[![Licence](https://img.shields.io/github/license/anjo0803/schrankenwaerter)](https://github.com/anjo0803/schrankenwaerter/blob/main/LICENCE.txt)
# schrankenwaerter
> [🇩🇪](#deutsch) // [🇬🇧](#english)

## Deutsch
Der **Schrankenwärter** ist ein Lua-Skript zur Steuerung von Bahnübergängen im
Eisenbahnsimulator EEP - vom einfachen BÜ mit zwei Schranken bis hin zu
komplexen Systemen aus vielen separaten Lichtzeichen, Schranken, Immobilien und
Sounds samt Zeitpuffern dazwischen!

### Einbinden des Skripts
Um das Schrankenwärter-Skript zu installieren, können Sie einfach
[hier](https://github.com/anjo0803/schrankenwaerter/releases/latest) die
neueste `Schrankenwaerter.zip`-Datei herunterladen und mittels des
EEP-Modellinstallers installieren. Dies platziert automatisch das
Schrankenwärter-Skript im "LUA"-Ordner ihrer EEP-Installation. Natürlich können
Sie auch die Datei
[`Schrankenwaerter.lua`](https://github.com/anjo0803/schrankenwaerter/blob/main/Schrankenwaerter.lua)
direkt herunterladen und selbst im "LUA"-Ordner platzieren.

Im Lua-Skript Ihrer Anlagen können Sie das Schrankenwärter-Skript dann mittels
der Lua-Funktion `require` einbinden:
```lua
SW = require("Schrankenwaerter")
```
Rufen Sie bitte außerdem die Funktion `SW.main()` in Ihrer `EEPMain()`-Funktion
auf, damit das Schrankenwärter-Skript auch ausgeführt wird:
```lua
function EEPMain()
	SW.main()
	return 1
end
```

### Konfigurieren eines BÜs
Ihre Bahnübergänge können Sie nach Einbindung des Schrankenwärter-Skripts mit
der Funktion `SW.setup` definieren:
```lua
SW = require("Schrankenwaerter")
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
EEPSaveData-Slots zuweisen. Dieser wird dann genutzt, um Ausführungsdaten für
den BÜ (bspw. Anzahl der nahenden Züge oder den als nächstes auszuführenden
Befehl) zu speichern, sodass diese Daten nicht beim Neuladen des Skripts oder
der Anlage verloren gehen. Die `ID` können Sie beliebig wählen (bspw
`"bue_beispielstr"` oder einfach numerisch `1`) oder auch auslassen - in diesem
Fall wird der entsprechende BÜ von Lua automatisch numerisch indexiert.

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
Beispielkonfigurationen für BÜs können Sie
[hier](https://github.com/anjo0803/schrankenwaerter/blob/main/Examples.lua)
finden.

### Kontaktpunkte
Nachdem die gewünschten BÜs definiert wurden, sind natürlich noch entsprechende
Kontaktpunkte zu erstellen. Darin haben Sie für die aufzurufende Lua-Funktion
zwei Möglichkeiten:

- Mittels [BetterContacts](https://github.com/EEP-Benny/BetterContacts) sollte
  es möglich sein, das Schrankenwärter-Skript direkt aufzurufen, indem Sie
  `SW.close(bue_id)` eintragen (und für `bue_id` die von Ihnen für den
  BÜ zuvor gewählte `ID` einsetzen).
- Alternativ können Sie selbstverständlich eine eigene Funktion definieren, die
  dann ihrerseits `SW.close(bue_id)` aufruft, und diese eintragen.

Für den BÜ wieder freigebende Kontaktpunkte muss nur sinngemäß die Funktion
`SW.open(bue_id)` aufgerufen werden.

### Lizenz
[Gemeinfrei kraft der Unlicense.](https://github.com/anjo0803/schrankenwaerter/blob/main/UNLICENSE.txt)

## English
**Schrankenwaerter** is a Lua script for controlling railroad crossings in the
train simulator EEP - from a simple crossing of just two signals to complex
setups of many separate lights, barriers, structures, and sounds plus time
buffers in between!

### Using the script
To use the Schrankenwaerter script in your railroad system, you can simply
download the latest `Schrankenwaerter.zip` file
[here](https://github.com/anjo0803/schrankenwaerter/releases/latest) and
install it using the EEP Model Installer. This will automatically place the
Schrankenwaerter script in the "LUA" folder of your EEP installation.
Naturally, you can also download the
[`Schrankenwaerter.lua`](https://github.com/anjo0803/schrankenwaerter/blob/main/Schrankenwaerter.lua)
file directly and place it in the "LUA" folder yourself.

You can then integrate the Schrankenwaerter script into the Lua script of your
layouts using the Lua `require` function:
```lua
SW = require("Schrankenwaerter")
```
Please also add a call to the `SW.main()` function in your `EEPMain()` function
in order for the Schrankenwaerter script to actually be executed:
```lua
function EEPMain()
	SW.main()
	return 1
end
```

### Crossing setup
After integrating the Schrankenwaerter script, you can define your railroad
crossings using the `SW.setup` function:
```lua
SW = require("Schrankenwaerter")
SW.setup({
	-- List of your railroad crossings here!
})
```

#### Data structure
In order for the script to correctly manage your crossings, they must be
described in the following structure:
```lua
[ID] = {
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
slots to the crossing. This will then be used to save the crossing's live
data (e.g. number of trains approaching the crossing or the command to execute
next), so that this isn't lost during reloads of the script or your layout. You
are also free to choose the `ID` (e.g. `"crossing_example_st"` or just
numerically `1`) or leave it out entirely, in which case Lua will automatically
index it numerically.

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
You can find example configurations for crossings
[here](https://github.com/anjo0803/schrankenwaerter/blob/main/Examples.lua).

### Contact points
Naturally, contact points corresponding to the defined railroad crossings still
need to be set up after. There are two possibilities for the Lua function to
call therein:

- Using [BetterContacts](https://github.com/EEP-Benny/BetterContacts), it
  should be possible to call the Schrankenwaerter script directly via
  `SW.close(crossing_id)` (replacing `crossing_id` with the `ID` you
  chose for the crossing earlier).
- Alternatively, you naturally can just define another function, which itself
  calls `SW.close(crossing_id)`, and use that.

In contact points that should open the crossing, simply call the
`SW.open(crossing_id)` function instead.

### Licence
[Public domain (via the Unlicense).](https://github.com/anjo0803/schrankenwaerter/blob/main/UNLICENSE.txt)
