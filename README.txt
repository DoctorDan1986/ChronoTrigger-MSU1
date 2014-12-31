Chrono Trigger MSU-1 hack
Version 1.0 (WIP)
by DarkShock

This hack adds CD quality audio to Chrono trigger using the MSU-1 chip invented by byuu. For next version I do hope to include the FMV from the PS1 version !

The hack has been tested on bsnes 075, higan 094 and SD2SNES.

========
= TODO =
========
* Use correct timing for fade-in/fade-out
* Credits/Epoch fix
* Hook fanfare ?
* FMV from the PS1 version (Version 2.0)

=====================
= Creating the .pcm =
=====================
First get Chrono Symphony album in FLAC format (http://www.thechronosymphony.com/). Extract them all to a folder.
Run decode_flac to convert FLAC files to WAV files
Use create_pcm.bat to create the .pcm from WAV files.

===============
= Using higan =
===============
1. Patch the ROM
2. Generate the .pcm
3. Launch it using higan
4. Go to %USERPROFILE%\Emulation\Super Famicom\rnrr_msu1.sfc in Windows Explorer.
5. Rename program.rom to chrono_msu1.sfc
6. Copy manifest.bml and the .pcm file there
7. Launch the game

===============
= Using BSNES =
===============
1. Patch the ROM
2. Generate the .pcm
3. Launch the game

====================
= Using on SD2SNES =
====================
Drop the ROM file, chrono_msu1.msu and the .pcm files in any folder. (I really suggest creating a folder)
Launch the game and voilà, enjoy !

=============
= Compiling =
=============
Source is availabe on GitHub: https://github.com/mlarouche/ChronoTrigger-MSU1

To compile the hack you need

* asar 1.36 (http://www.smwcentral.net/?p=section&a=details&id=6000)
* flac (https://xiph.org/flac/download.html)
* wav2msu (http://helmet.kafuka.org/thepile/Wav2msu)

To distribute the hack you need

* uCON64 (http://ucon64.sourceforge.net/)
* 7-Zip (http://www.7-zip.org/)

create_pcm.bat create the .pcm from the WAV files
decode_flac.bat decode the FLAC from the Chrono Symphony album
distribute.bat distribute the patch
make.bat assemble the patch
make_all.bat does everything
