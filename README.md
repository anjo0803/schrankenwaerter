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
[hier](https://github.com/anjo0803/schrankenwaerter/releases/latest/download/Schrankenwaerter.zip)
die neueste `Schrankenwaerter.zip`-Datei herunterladen und dann mittels des
EEP-Modellinstallers installieren. Dies platziert automatisch das
Schrankenwärter-Skript im "LUA"-Ordner Ihrer EEP-Installation. Alternativ
können Sie auch die Datei
[`Schrankenwaerter.lua`](https://github.com/anjo0803/schrankenwaerter/blob/main/Schrankenwaerter.lua)
direkt herunterladen und manuell im "LUA"-Ordner platzieren.

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
Ihre Bahnübergänge können Sie nach Einbindung des Schrankenwärter-Skripts
jeweils mit der Funktion `SW.define`/`SW.definiere` - die meisten Funktionen
können sowohl über einen englischen als auch einen deutschen Namen aufgerufen
werden - definieren. Dabei müssen Sie dem BÜ eine ID geben, über die Sie ihn
dann später ansteuern können.
```lua
SW.definiere("Beispiel-BÜ")
```
Alle weiteren für die Steuerung relevanten Daten werden direkt dahinter in
zusätzlichen Funktionen beschrieben.

#### Zuweisen von Speicher-Slots
Optional können Sie dem BÜ einen der EEPSaveData-Slots zuweisen. Dieser wird
dann genutzt, um Zustandsdaten des BÜs (bspw. Anzahl der nahenden Züge) zu
speichern, sodass diese nicht beim Neuladen des Skripts oder der Anlage
verloren gehen.
```lua
SW.definiere("Beispiel-BÜ")
	:speichern(1)
```

#### Befehle
Mit den Funktionen `:schliessen` und `:oeffnen` der BÜ-Definition können Sie
detailliert beschreiben, wie genau der Öffnungs- und Schließvorgang des
jeweiligen BÜs aussehen soll. Optional steht noch die Funktion `:doppelt`
zur Verfügung, wenn Sie für den Fall, dass ein zweiter Zug den bereits
geschlossenen BÜ aktiviert, weitere Aktionen ausführen wollen, bspw. die
Aktivierung der Leuchtschrift an einem "2 Züge"-Blinklicht.
```lua
SW.definiere("Beispiel-BÜ")
	:speichern(1)
	:schliessen(befehl1, befehl2, ...)
	:oeffnen(befehl1, befehl2, ...)
	:doppelt(befehl1, befehl2, ...)
```

Diese drei Funktionen benötigen jeweils eine Liste von "Befehlen", die während
des jeweiligen Vorgangs nacheinander abgearbeitet werden. Dies kann bspw. der
Befehl sein, ein Signal umzuschalten oder einen Sound ein- oder auszuschalten.
Momentan werden folgende Befehle vom Skript selbst bereitgestellt:
| Name | Effekt | Parameter |
|-|-|-|
| `SW.signal(signal_id, stellung)` | Setzt ein Signal in eine Stellung. | `signal_id`: ID des Signals, das gesetzt werden soll.<br>`stellung`: ID der Stellung, in die das Signal gesetzt werden soll. |
| `SW.immo(immo_id, achse, schritte)` | Bewegt eine Achse an einer Immobilie. | `immo_id`: Lua-Name der Ziel-Immobilie.<br>`achse`: Name der zu bewegenden Achse.<br>`schritte`: Anzahl der Schritte, die die Achse bewegt werden soll. |
| `SW.sound(sound_id, anschalten)` | Schaltet einen Sound an oder aus. | `sound_id`: Lua-Name des Ziel-Sounds.<br>`anschalten`: `true`, um den Sound anzuschalten; `false`, um ihn auszuschalten. |
| `SW.pause(zyklen)` | Pausiert die Befehlsausführung. | `zyklen`: Anzahl der Lua-Zyklen, für die die Ausführung ruhen soll. Ein Zyklus entspricht einem Aufruf der `SW.main()`-Funktion, d.h. wenn diese in jedem Aufruf der `EEPMain()`-Funktion aufgerufen wird, dauert jeder Zyklus 200ms. |

#### Beispiele
Beispielkonfigurationen für BÜs können Sie
[hier](https://github.com/anjo0803/schrankenwaerter/blob/main/Examples.lua)
finden. *Anm.: Die Beispiele nutzen die englischen Namen der Funktionen.*

### Kontaktpunkte
Die An- und Abmeldung von Zügen an BÜs geschieht über die Funktionen
`SW.schliesse(bue_id)` und `SW.oeffne(bue_id)`. Für `bue_id` müssen Sie die
von Ihnen zuvor gewählte ID des jeweils anzusteuernden BÜs einsetzen.

Mittels [BetterContacts](https://github.com/EEP-Benny/BetterContacts) sollte
es möglich sein, diese Funktionen direkt aus den zu setzenden Kontaktpunkten
heraus aufzurufen. Ansonsten können Sie natürlich für jeden BÜ eigene
Funktionen definieren, die dann ihrerseits die Schrankenwärter-Funktionen mit
der korrekten BÜ-ID aufrufen.

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
[here](https://github.com/anjo0803/schrankenwaerter/releases/latest/download/Schrankenwaerter.zip)
and install it using the EEP Model Installer. This will automatically place the
Schrankenwaerter script in the "LUA" folder of your EEP installation.
Alternatively, you can also download the
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
crossings using the `SW.define` function. You must pass an ID value to this
function, which you can then use to address this specific crossing:
```lua
SW = require("Schrankenwaerter")
SW.define("Example Crossing")
```
All other relevant data is described right afterwards using additional
functions.

#### Assigning save slots
Optionally, you can assign the crossing one of the EEPSaveData slots. This will
then be used to save the crossing's live data (e.g. number of trains
approaching the crossing), so that this isn't lost during reloads of the script
or your layout.
```lua
SW.define("Example Crossing")
	:save(1)
```

#### Commands
Using the functions `:closing` and `:opening`, you can describe in detail how
you want the closing and opening sequences of the respective crossing to look.
You can also use the function `:twice` to optionally execute an additional
sequence when a second train strikes into the already-closed crossing, for
example to illuminate the lettering on a "2 Züge" signal.
```lua
SW.define("Example Crossing")
	:save(1)
	:closing(command1, command2, ...)
	:opening(command1, command2, ...)
	:twice(command1, command2, ...)
```

These three functions each require a list of "commands", which will be executed
one after another during the respective sequence. Examples of commands are to
set a signal or turn a sound on or off. Currently, the script itself provides
the following commands:
| Name | Effect | Parameters |
|-|-|-|
| `SW.signal(signal_id, position)` | Set a signal. | `signal_id`: ID of the target signal.<br>`position`: ID of the position that the signal should be set to. |
| `SW.immo(immo_id, axis, steps)` | Moves an axis on a structure. | `immo_id`: Lua name of the target structure.<br>`axis`: Name of the axis to move.<br>`steps`: Number of steps to move the axis. |
| `SW.sound(sound_id, turn_on)` | Turns a sound on or off. | `sound_id`: Lua name of the target sound.<br>`turn_on`: `true` to turn on the sound; `false` to turn it off. |
| `SW.pause(cycles)` | Pauses execution of commands. | `cycles`: Number of Lua cycles to pause. One cycle is equivalent to one call of the `SW.main()` function, so if it is called with every call of the `EEPMain()` function, one cycle is 200ms. |

#### Examples
You can find example configurations for crossings
[here](https://github.com/anjo0803/schrankenwaerter/blob/main/Examples.lua).

### Contact points
Trains can strike in and pass the crossing using the `SW.close(crossing_id)`
and `SW.open(crossing_id)` functions. The `crossing_id` is the ID you chose
earlier for the respective crossing.

Using [BetterContacts](https://github.com/EEP-Benny/BetterContacts), it should
be possible to call these functions directly from the contact points set for
the crossing. Alternatively, you naturally can just define another function,
which itself calls `SW.close(crossing_id)`, and use that.

### Licence
[Public domain (via the Unlicense).](https://github.com/anjo0803/schrankenwaerter/blob/main/UNLICENSE.txt)
