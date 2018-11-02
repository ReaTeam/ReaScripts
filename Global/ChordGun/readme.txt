-- @noindex

if you're making changes, for example if you're modifying /src/interface/handleInput.lua to change keyboard shortcuts when GUI interface has focus then make sure to:

1. save your changes
2. run `bash unify.sh`
3. load scripts into Reaper from the /pkg directory


keyboard shortcuts (when GUI has focus)
--------------------

0 - stop all notes from playing

1 - play scale chord 1
2 - play scale chord 2
3 - play scale chord 3
4 - play scale chord 4
5 - play scale chord 5
6 - play scale chord 6
7 - play scale chord 7

q - higher scale note 1
w - higher scale note 2
e - higher scale note 3
r - higher scale note 4
t - higher scale note 5
y - higher scale note 6
u - higher scale note 7

a - scale note 1
s - scale note 2
d - scale note 3
f - scale note 4
g - scale note 5
h - scale note 6
j - scale note 7

z - lower scale note 1
x - lower scale note 2
c - lower scale note 3
v - lower scale note 4
b - lower scale note 5
n - lower scale note 6
m - lower scale note 7

ctrl+, - decrement scale tonic note
ctrl+. - increment scale tonic note
ctrl+shift+, - decrement scale type
ctrl+shift+. - increment scale type

option+, - halve grid size
option+. - double grid size
option+shift+, - decrement octave
option+shift+. - increment octave

command+, - decrement chord type
command+. - increment chord type
command+shift+, - decrement chord inversion
command+shift+. - increment chord inversion
