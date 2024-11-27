@echo off
chcp 1252

(
	echo [Install_00]
	echo Name_GER = "Schrankenwaerter %~1"
	echo Name_ENG = "Schrankenwaerter %~1"
	echo Name_FRA = "Schrankenwaerter %~1"
	echo Name_POL = "Schrankenwaerter %~1"
	echo Desc_GER = "Lua-Skript zum Steuern von Bahnübergängen."
	echo Desc_ENG = "Lua script for controlling railroad crossings."
	echo Desc_FRA = "Script Lua pour le commande des passages à niveau."
	echo Desc_POL = "Skrypt Lua do kontrolowania przejazdów kolejowych."
	echo Script = "Install_00\Install.ini"
) > Installation.eep

mkdir Install_00
copy Schrankenwaerter.lua Install_00\
(
	echo [EEPInstall]
	echo EEPVersion = 10
	echo File001 = "Schrankenwaerter.lua","LUA\Schrankenwaerter.lua"
) > .\Install_00\Install.ini

7z a -tzip Installable.zip Installation.eep Install_00
