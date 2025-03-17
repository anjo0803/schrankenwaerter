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
Um das Schrankenwärter-Skript zu installieren, kannst Du einfach
[hier](https://github.com/anjo0803/schrankenwaerter/releases/latest/download/Schrankenwaerter.zip)
die neueste `Schrankenwaerter.zip`-Datei herunterladen und dann mittels des
EEP-Modellinstallers installieren. Dadurch wird das Skript automatisch im
"LUA"-Ordner Deiner EEP-Installation platziert. Alternativ kann auch die Datei
[`Schrankenwaerter.lua`](https://github.com/anjo0803/schrankenwaerter/blob/main/Schrankenwaerter.lua)
direkt heruntergeladen und manuell im "LUA"-Ordner gespeichert werden.

Im Lua-Skript der Anlagen kann das Skript dann durch die Lua-Funktion `require`
eingebunden werden:
```lua
SW = require("Schrankenwaerter")
```
Außerdem muss die Funktion `SW.main()` in der `EEPMain()`-Funktion aufgerufen
werden, damit das Skript auch tatsächlich ausgeführt wird:
```lua
function EEPMain()
	SW.main()
	return 1
end
```

### Konfigurieren eines BÜs
Bahnübergänge kannst Du nach Einbindung des Skripts jeweils einzeln mit der
Funktion `SW.define` bzw. `SW.definiere` konfigurieren - die meisten Funktionen
des Skripts haben sowohl einen englischen als auch einen deutschen Namen. Dabei
muss dem BÜ zuerst eine ID gegeben werden, über die er im folgenden angesteuert
werden soll.
```lua
SW.definiere("Beispiel-Bue")
```
Direkt danach kannst Du die gewünschten Eigenschaften des BÜ beschreiben.

#### Zuweisen von Speicher-Slots
Optional lässt sich jedem BÜ ein EEPSaveData-Slot zuweisen. Dieser wird dann
genutzt, um Zustandsdaten des BÜs (bspw. Anzahl der nahenden Züge) zu sichern,
sodass diese nicht beim Neuladen des Skripts oder der Anlage verloren gehen.
```lua
SW.definiere("Beispiel-Bue")
	:speichern(1)
```

#### Schließ- und Öffnungsvorgang
Den Kern der BÜ-Konfiguration bilden Schließ- und Öffnungsvorgang, die über
die Funktionen `:schliessen` bzw. `oeffnen` eingestellt werden. Darin kannst
Du mittels einer Kette von "Befehlen" detailliert beschreiben, wie diese
Vorgänge konkret ablaufen sollen.
```lua
SW.definiere("Beispiel-Bue")
	:speichern(1)
	:schliessen(befehl1, befehl2, ...)
	:oeffnen(befehl1, befehl2, ...)
```

Die angegebenen Befehle werden während des jeweiligen Vorgangs nacheinander
abgearbeitet. Momentan stehen folgende Befehle zur Verfügung:
| Name | Effekt | Parameter |
|-|-|-|
| `SW.signal(signal_id, stellung)` | Setzt ein Signal in eine Stellung. | `signal_id`: ID des Signals, das gesetzt werden soll.<br>`stellung`: ID der Stellung, in die das Signal gesetzt werden soll. |
| `SW.immo(immo_id, achse, schritte)` | Bewegt eine Achse an einer Immobilie. | `immo_id`: Lua-Name der Ziel-Immobilie.<br>`achse`: Name der zu bewegenden Achse.<br>`schritte`: Anzahl der Schritte, die die Achse bewegt werden soll. |
| `SW.sound(sound_id, anschalten)` | Schaltet einen Sound an oder aus. | `sound_id`: Lua-Name des Ziel-Sounds.<br>`anschalten`: `true`, um den Sound anzuschalten; `false`, um ihn auszuschalten. |
| `SW.pause(zyklen)` | Pausiert die Befehlsausführung. | `zyklen`: Anzahl der Lua-Zyklen, für die die Ausführung ruhen soll. Ein Zyklus entspricht einem Aufruf der `SW.main()`-Funktion, d.h. wenn diese in jedem Aufruf der `EEPMain()`-Funktion aufgerufen wird, dauert jeder Zyklus 200ms. |

#### Doppelaktivierung
Neben `:schliessen` und `:oeffnen` lässt sich optional ein Vorgang definieren,
der ausgeführt werden soll, wenn ein zweiter Zug sich am bereits geschlossenen
BÜ anmeldet. So lässt sich bspw. die Aktivierung einer "2 ZÜGE"-Leuchtschrift
verwirklichen. Ein solcher Vorgang wird über die Funktion `:doppelt` definiert,
wobei wie bei Schließ- und Öffnungsvorgang Befehle benutzt werden:
```lua
SW.definiere("Beispiel-Bue")
	:speichern(1)
	:schliessen(befehl1, befehl2, ...)
	:oeffnen(befehl1, befehl2, ...)
	:doppelt(befehl1, befehl2, ...)
```

#### Anrufschranken
Möchtest Du einen Bahnübergang als Anrufschranke einrichten, musst Du in der
BÜ-Definition nur die entsprechende Funktion aufrufen:
```lua
SW.definiere("Beispiel-Bue")
	:speichern(1)
	:anrufschranke()
	:schliessen(befehl1, befehl2, ...)
	:oeffnen(befehl1, befehl2, ...)
```

#### Beispiele
Beispielkonfigurationen für BÜs gibt es
[hier](https://github.com/anjo0803/schrankenwaerter/blob/main/Examples.lua)!
*Anm.: Die Beispiele nutzen die englischen Namen der Funktionen.*

### Kontaktpunkte
Um einen BÜ dann tatsächlich zu schließen und zu öffnen, müssen sich Züge
einfach über die Funktionen `SW.schliesse(bue_id)` und `SW.oeffne(bue_id)` am
BÜ an- bzw. abmelden Die `bue_id` entspricht dabei der zuvor von Dir gewählten
BÜ-ID.

Zur straßenseitigen Steuerung von Anrufschranken werden zusätzlich die
Funktionen `SW.anrufen(bue_id)` und `SW.freimelden(bue_id)` benutzt. Durch sie
kann ein Verkehrsteilnehmer die Öffnung der Schranke anfordern bzw. melden,
dass der Übergang wieder geräumt ist.

Mittels [BetterContacts](https://github.com/EEP-Benny/BetterContacts) ist es
möglich, diese Funktionen direkt aus Kontaktpunkten heraus aufzurufen.
Ansonsten müssen für jeden BÜ spezifische Funktionen eingefügt werden, die dann
ihrerseits die Schrankenwärter-Funktionen aufrufen:
```lua
function schliesse_beispiel()
	SW.schliesse("Beispiel-Bue")
end
function oeffne_beispiel()
	SW.oeffne("Beispiel-Bue")
end
```

Natürlich können die Öffnungs- und Schließungsfunktionen auch außerhalb von
Kontaktpunkten, bspw. an anderer Stelle des Anlagen-Skripts, aufgerufen werden.

### Lizenz
Ich habe das Skript für faktisch gemeinfrei erklärt
([Unlicense](https://github.com/anjo0803/schrankenwaerter/blob/main/UNLICENSE.txt)).

## English
**Schrankenwaerter** is a Lua script for controlling railroad crossings in the
train simulator EEP - from a simple crossing of just two signals to complex
setups of many separate lights, barriers, structures, and sounds plus time
buffers in between!

### Using the script
To use the Schrankenwaerter script in your layouts, you can simply download the
latest `Schrankenwaerter.zip` file
[here](https://github.com/anjo0803/schrankenwaerter/releases/latest/download/Schrankenwaerter.zip)
and install it using the EEP Model Installer. This will automatically place the
script in the "LUA" folder of your EEP installation. Alternatively, you can
also download the
[`Schrankenwaerter.lua`](https://github.com/anjo0803/schrankenwaerter/blob/main/Schrankenwaerter.lua)
file directly and place it in the "LUA" folder yourself.

You can then integrate the Schrankenwaerter script into the Lua script of a
layout using the Lua `require` function:
```lua
SW = require("Schrankenwaerter")
```
Please also add a call to the `SW.main()` function in your `EEPMain()` function
in order for the script to actually be executed:
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
```lua
SW.define("Example Crossing")
	:save(1)
	:closing(command1, command2, ...)
	:opening(command1, command2, ...)
```

These functions each require a list of "commands", which will be executed one
after another during the respective sequence. For example, you can set a signal
or turn a sound on or off. Currently, the script provides the following
commands:
| Name | Effect | Parameters |
|-|-|-|
| `SW.signal(signal_id, position)` | Set a signal. | `signal_id`: ID of the target signal.<br>`position`: ID of the position that the signal should be set to. |
| `SW.immo(immo_id, axis, steps)` | Moves an axis on a structure. | `immo_id`: Lua name of the target structure.<br>`axis`: Name of the axis to move.<br>`steps`: Number of steps to move the axis. |
| `SW.sound(sound_id, turn_on)` | Turns a sound on or off. | `sound_id`: Lua name of the target sound.<br>`turn_on`: `true` to turn on the sound; `false` to turn it off. |
| `SW.pause(cycles)` | Pauses execution of commands. | `cycles`: Number of Lua cycles to pause. One cycle is equivalent to one call of the `SW.main()` function, so if it is called with every call of the `EEPMain()` function, one cycle is 200ms. |

#### Double activation
In addition to `:closing` and `:opening`, you can optionally define a routine
to be executed when a second train activates the already closed crossing. This
e.g. allows for the activation of a "2 ZÜGE" display. To create such a routine,
use the `:twice` function with commands, just as above.
```lua
SW.define("Example Crossing")
	:save(1)
	:closing(command1, command2, ...)
	:opening(command1, command2, ...)
	:twice(command1, command2, ...)
```

#### Call-only crossings
If you want to run a crossing like a British MCB-OC type - having the barriers
down permanently and only opening them if a road user requests it - you just
need to chain the corresponding function during the crossing setup:
```lua
SW.define("Example Crossing")
	:save(1)
	:call_only()
	:closing(command1, command2, ...)
	:opening(command1, command2, ...)
```

#### Examples
You can find example configurations for crossings
[here](https://github.com/anjo0803/schrankenwaerter/blob/main/Examples.lua).

### Contact points
Trains can strike in and pass the crossing using the `SW.close(crossing_id)`
and `SW.open(crossing_id)` functions. The `crossing_id` is the ID you chose
earlier for the respective crossing.

For controlling a call-only crossing on the side of the road users, the
`SW.call_request(crossing_id)` and `SW.call_clear(crossing_id)` functions are
used additionally. They signal that a road user requests opening the barriers
and that they have cleared the crossing again, respectively.

Using [BetterContacts](https://github.com/EEP-Benny/BetterContacts), it is
possible to call these functions directly from the contact points set for the
crossing. Alternatively, you naturally can just define another function, which
itself calls `SW.close(crossing_id)`, and use that.
```lua
function close_example()
	SW.close("Example Crossing")
end
function open_example()
	SW.open("Example Crossing")
end
```

Naturally, you can also call the opening and closing functions outside of
contact points from another part of your layout's script.

### Licence
[Public domain (Unlicense).](https://github.com/anjo0803/schrankenwaerter/blob/main/UNLICENSE.txt)
