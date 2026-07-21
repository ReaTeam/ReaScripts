# ReaChorder
ReaChorder Python plugin for Reaper DAW

About
-----
ReaChorder is a Python extension/plugin that enables you to generate songs in MIDI format. It does this by applying music theory. You can choose song formula, the key and whether it needs to be Major or Minor. It then uses the circle of fifths to propose chord progression and randomly chooses and combines different chord inversions, melodies and bass lines. It also has a drum sequencer with many drum pattern presets.

# What does it do?
A demo song (part) was created with a single click, using the "Catchy" chord progression. Using Synth1 for all tracks:
https://github.com/flaneurette/ReaChorder/blob/master/Binaries/RC-song.mp3?raw=true

# What does it look like?

<img src="https://raw.githubusercontent.com/flaneurette/ReaChorder/master/images/screenshot.png" />

# Requirements:

Minimum required software
- Reaper 4.5.2+: http://reaper.fm/
- Python: http://www.python.org/download/releases/3.3.0/
- SWS extension: http://www.standingwaterstudios.com/

# Installing
1.  Make sure you have Python installed. To download, visit: https://www.python.org/downloads/
2.  Clone or download ReaChorder, and copy all files into your Reaper /Scripts/ folder
3.  Add a new menu item in the midi editor and locate ReaChorder.py.

# Adding to Reaper

Adding Python to your Reaper, click use ReaScript. Locate the path and force Reaper to find the Python version.

<img src="https://raw.githubusercontent.com/flaneurette/ReaChorder/master/images/reaper-pref.png" />

Then, in the MIDI editor, edit the menu (right click in menu) and add a new ReaScript, locate Reachorder and click add.

<img src="https://raw.githubusercontent.com/flaneurette/ReaChorder/master/images/reaper-action-list.png" />

# Discussion

Visit the Reaper forum for discussion: https://forum.cockos.com/showthread.php?t=200185
