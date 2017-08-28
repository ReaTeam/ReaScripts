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
1. Use the _marker/region list_ to move through the project. Filtering for
   __components__ that included the vocalist that I was recording.
1. Record each clip in the position that it was intended.

At this point, I had recorded clips whose _starting positions_ were in the
proper place.  There were a few problems that still needed to be addressed.

* The beginnings and endings of the clips had silent moments that needed to be
  edited out.
* The lengths of the recorded clips was not the same as the length of the _EMPTY
  MIDI Item_ that held its place.

### Editing

1. For _every single clip_ in the project:
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
by machine. For example, here's what a basic Clip Splicer JSON file might look
like:

```json
{
  type: "REGION",
  name: "Simple example",
  components: [
    {
      type: "CLIP",
      name: "Word1",
      track: "Person1",
      filename: "Person1-Word1.wav"
    }, 
    {
      type: "PAUSE",
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
            |- - - - - - - - A region named "Simple example"  - - - - - - -|
            |- - "CLIP: Person1 Word1" - -||- "PAUSE: Pause after clip."  -|
→Timeline→
↓Tracks↓   
Beethoven | |- Clip: "Person1-Word1.wav" -|
Pause     |                                |- Empty MIDI Item (length 2s) -|
```
Notice:
* Regions are created to _contain_ their components.
* Regions are created for _each_ component.
* Clips are aligned _in sequence_, regardless of length.
* Clips are put on the _proper track_.


