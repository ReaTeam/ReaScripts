# Clip Splicer

## Motivation

I make CDs for an English language school. A single track in a typical project
usually comprised a few __instructions__ followed by a lot of __words__, each 
with spaces for __repeats__ and __pauses__ to allow listeners to practice. When 
I first started doing this, my process was something like this:

### Setup

1. Obtain a _script_ of the entire CD project. 
   * The script would define the layout of each __track__. Something like this: 
     * [Instruction 1A], Cat, Dog, Elephant, ...
1. Create a _skeleton_ REAPER session file that contained _Empty MIDI Items_ for
   each of the __components__ that would _eventually_ be recorded in the
   project.
1. Name the _Empty MIDI Items_ according to the _word_ that would _eventually_
   be recorded.
1. Put _regions_ and _markers_ on all the __components__ and __tracks__.

At this point, I had a _skeleton_ of what the final project would look like.

### Recording

1. Setup microphones to record each vocalist.
1. Use the _Region/Marker Manager_ to move through the project. Filtering for
   __components__ that included the vocalist that I was recording.
1. Record each clip in the position that it was intended.

At this point, I had recorded clips whose _starting positions_ were in the
proper place.  There were a few problems that still needed to be addressed.

* The beginnings and endings of the clips had silent moments that needed to be
  edited out.
* The lengths of the recorded clips was not the same as the length of the _EMPTY
  MIDI Item_ that held its place.

### Editing

For _every single clip_ in the project:
1. Manually trim the silence at the beginning and end of the clip.
1. Using _global ripple editing_, move the _following components_ to the
   right, so they began where the previous __component__ ended.

As you may guess, that could take a _very_ long time if there were hundreds or
thousands of _individual clips_ to edit.

However, at this point, the session was ready to be mixed for audio.

### Revisions

Revision requests often came in the form of:

* Please make the pauses after _all the instructions_ a bit longer.
* Please re-record the word "cat" and replace _all instances_ with the new
  recording.

Although revisions weren't terribly difficult to do, the amount of editing was
still similar to the original amount of editing. Also, on a not-so-fast
machine, editing files within a mixing session was often sluggish, with all the
plugins running. Some sessions include gigabytes of .wav files loaded into
memory. Some files appeared multiple times within the session.

Enter __Clip Splicer__.

## Overview

_Clip Splicer_ is used to automatically assemble components into a REAPER
project.

The components are defined by a simple JSON file that can be created by hand, or
by machine. For example, here's what a basic __Clip Splicer__ JSON file might 
look like:

```json
{
  type: "REGION",
  name: "Simple example",
  components: [
    {
      type: "MEDIA ITEM",
      track: "Person1",
      name: "Word1",
      filename: "P1-W1.wav"
    }, 
    {
      type: "MEDIA ITEM",
      name: "Pause after clip."
      length: 2
    }
  ]
}
```
The above example would generate a REAPER session that looks something like
this:

```
→Regions→
            |- - - - - - - -  A region named "REGION: Simple example" - - - - - - -|
→Timeline→
↓Tracks↓   
Beethoven | |- -  Media Item: "P1-W1.wav"  - - -|
SILENCE   |                                      |-  Empty Media Item (length 2s) -|
```
Notice:
* Regions are created to _contain_ their components.
* Media Items are aligned _in sequence_, regardless of length.
* Media Items are put on the _proper track_.

## A closer look at the JSON object

__Clip Splicer__ attempts to model the data as simply as possible. Refer to
http://www.json.org for some inspiration.

Keep in mind that anything in your REAPER session that should be _ordered_ needs
to be within an array in the JSON file. In the above example, the main REGION
("Simple example") is the _only_ top-level REGION in the specification. A __Clip
Splicer__ specification __*requires*__ a single, top-level REGION.

There are two types of __Clip Splicer__ objects:

1. REGION - Used as a _wrapper_ to surround internal components.
1. MEDIA ITEM - Used to represent an _audio file_ or a period of _silence_.

One of the powerful features of __Clip Splicer__ is that REGIONs can be
_nested_. For example, imagine this:

* You are creating a single project that should contain 5 _discs_ (as in CDs).
* Each _disc_ has a few dozen _tracks_ (as in tracks on a CD). 
* Each _track_ has two _sections_:
  * An _instructions_ section.
  * A _content_ section.
* Each _section_ has many _clips_ and _silences_.

In the above example, there are _discs_, _tracks_, _sections_, _instructions_,
and _contents_. For all of those cases, _ordering_ is important.
When you are navigating your REAPER session, you also want to be able to quickly
move through the _Region/Marker Manager_ to get to all of the elements'
positions.  When you want to render your project to it's final form, you also
want to be able to render all of the _tracks_ as individual .wav files, and put
them into properly named folders for each of the _discs_.

This can all be done by _nesting_ REGIONs within each other. Just give all of
the REGIONs an appropriate name. For example:

* "DISC - Disc 01"
* "TRACK - Track 00"

When __Clip Splicer__ creates your REAPER project, all of the REGIONs will be
named. You can filter the REGIONs that you want in the _Region / Marker
Manager_.

Here's a slightly more complex __Clip Splicer__ JSON file example:

```
{
  type: "REGION",
  name: "Slightly more complex example project.",
  components: [
    {
      type: "REGION",
      name: "DISC - Disc 01", 
      components: [
        {
          type: "REGION",
          name: "TRACK - Track 00",
          components: [
            {
              type: "REGION",
              name: "Instructions",
              components: [
                {
                  type: "MEDIA ITEM",
                  filename: "Instruction 01.wav"
                },
                {
                  type: "MEDIA ITEM",
                  filename: "Instruction 02.wav"
                }
              ]
            },
            {
              type: "REGION",
              name: "Content",
              components: [
                {
                  type: "MEDIA ITEM",
                  filename: "Content 01.wav"
                },
                {
                  type: "MEDIA ITEM",
                  filename: "Content 02.wav"
                }
              ]
            }
          ]
        },
        {
          type: "REGION",
          name: "TRACK - Track 01", 
          components: [ ... ]
        }
      ]
    },
    {
      type: "REGION",
      name: "DISC - Disc 02", 
      components: [ ... ]
    }
  ]
}
```

### JSON objects

There are only 2 basic JSON object types:

* ```REGION```
* ```MEDIA ITEM```

#### REGION

A ```REGION``` is used to _wrap_ and _contain_ a series of _components_. 

Here are the valid members of a ```REGION``` object:

* ```type``` (string) (__required__) : This _must_ be "REGION" in order to be
  interpreted properly.
* ```name``` (string) (optional) : If defined, the _REAPER Region_ will be named
  "[name]"
* ```track``` (string) (optional) : If specified, all components will be added to this
  track, unless overridden. If not, the _inherited_ track will be used. If there
  is no _inherited_ track, a track with no name will be used.
* ```path``` (string) (optional) : If specified, all components' paths will be
  relative to this path. If not, the _inherited_ path will be used.  If there is 
  no _inherited_ path, the root path will be used. The root path is the 
  location of the JSON file itself.
* ```components``` (array) (optional) : If defined, the objects _within_ the array
  will be interpreted and imported into this ```REGION```. If empty or 
  undefined, the ```REGION``` will have length 0.

Here's an example ```REGION``` with all the bells and whistles:

```
{
  type: "REGION",
  name: "Super Duper Region",
  track: "Cowbell",
  path: "clips/percussion/cowbell/",
  components: [...]
}
```

For ```REGION``` objects, __Clip Splicer__ will:

1. Start a _REAPER region_ at the beginning of the object.
1. Render all of the _components_ within the object in their proper sequence.
1. End the _REAPER region_ at the end of the last _component_.

#### MEDIA ITEM

A ```MEDIA ITEM``` is used to represent an _audio file_ or _period of silence_.

Here are the valid member of a ```MEDIA ITEM``` object:

* ```type``` (string) (__required__) : This _must_ be "MEDIA ITEM" in order to be
  interpreted properly.
* ```name``` (string) (optional) : If defined, the _REAPER Media Item_ will be named
  "[name]".
* ```track``` (string) (optional) : If specified, this _REAPER Media Item_ will be 
  added to this track. If not, the _inherited_ track will be used. If there
  is no _inherited_ track, a track with no name will be used.
* ```filename``` (string) (optional) : If specified, __Clip Splicer__ will look for a
  file with the specified filename, relative to the path, and place it in the
  _REAPER Media Item_. If not, an empty _REAPER Media Item_ will be used.
* ```length``` (number) (optional) : If specified, the _REAPER Media Item_ will use
  the specified length (in seconds). If not, the file's original length will be
  used. If the specified length is _shorter_ than the file's length, the end of
  the file will be truncated. If the specified length is _longer_ than the
  file's length, the audio will be looped to reach the length.
* ```mute``` (true/false) (optional) : If true, the _REAPER Media Item_ will be muted. 

Here's an example ```MEDIA ITEM``` with all the bells and whistles.

```
{
  type: "MEDIA ITEM",
  name: "Super Duper Item",
  track: "Aux. Percussion",
  filename: "TheFever.wav",
  length: 1000,
  mute: true
}
```

### path

If an object specifies a ```path```, all internal components within
that ```REGION``` will _inherit_ the specified ```path```. Internal components
can, however, _override_ their parent's ```path``` by specifying a new
```path``` that begins with "/". Internal components can _extend_ their parent's
path by specifying a new ```path``` that begins does __not__ begin with "/".

All ```path```s are relative to the directory that contains the JSON file. 
Similar to how *nix filesystem paths work, a ```path``` that begins with "/" is
relative to the _root_. In this case, the _root_ is the JSON file's directory.
