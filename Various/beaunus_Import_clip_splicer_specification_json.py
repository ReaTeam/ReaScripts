# pylint: disable=pointless-string-statement
# pylint: disable=undefined-variable
# pylint: disable=trailing-whitespace
# pylint: disable=line-too-long
# pylint: disable=invalid-name
# pylint: disable=too-many-arguments
"""
ReaScript Name: Import Clip Splicer JSON file
About:
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
    "title": "Simple Clip Splicer Example.",
    "components": [
    {
      "type": "REGION",
      "name": "Simple example",
      "components": [
        {
          "type": "MEDIA ITEM",
          "track": "Person1",
          "name": "Word1",
          "filename": "P1-W1.wav"
        },
        {
          "type": "MEDIA ITEM",
          "name": "Pause after clip.",
          "length": 2
        }
      ]
    }]
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

  ## Workflow

  ### Import the specification into a REAPER session.

  1. Run the script `Script: beaunus_Import_reaper_clip_splicer_json.py`
  1. Select a .json file that contains a REAPER Clip Splicer specification.
     + If you are having trouble importing your JSON file, try validating your
       JSON file with schema/ClipSplicerSchema.json
  1. Examine the generated _missing file report_ to see what needs to be recorded.
    - The report can be found in the same folder as the .json file.

  ### Record the clips

  1. If the _missing file report_ is simple enough to manually trim each clip,
  simply record the clips without a lyrics track.
  1. If you want to automated the trimming process:
    1. Import the _missing file report_ into a lyrics track in a REAPER
    session.
    1. Convert the lyrics to markers.
       + `beaunus_Add markers for lyrics in selected items.lua`
    1. Set a reasonable tempo. In fact a super slow tempo will allow lots of time
       between clips.
    1. Record the clips in order.
       + You can easily navigate through the clip areas by using the marker
         manager.

  ### Trim and save the clips

  Performances should be __loudness normalized__ to -23LUFS.

  If you have used a lyrics track:

  1. Split the performance using dynamic split.
  1. Trim silence at the beginnings and ends of clips.
  1. Name the takes according to the marker that cuts them.
     + `beaunus_Name item takes by last marker to cut item.lua`
  1. Select the recorded, trimmed, items.
  1. Render items

  After all the clips have been recorded, you can again 'Import the
  specification into a REAPER session.'

  ## A closer look at the JSON object

  __Clip Splicer__ attempts to model the data as simply as possible. Refer to
  http://www.json.org for some inspiration.

  Keep in mind that anything in your REAPER session that should be _ordered_ needs
  to be within an array in the JSON file. In the above example, the main REGION
  ("Simple example") is the _only_ REGION in the specification's components.
  A __Clip Splicer__ specification __*requires*__ at least one component in the
  "components" member.

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
    "type": "REGION",
    "name": "Slightly more complex example project.",
    "components": [
      {
        "type": "REGION",
        "name": "DISC - Disc 01",
        "components": [
          {
            "type": "REGION",
            "name": "TRACK - Track 00",
            "components": [
              {
                "type": "REGION",
                "name": "Instructions",
                "components": [
                  {
                    "type": "MEDIA ITEM",
                    "filename": "Instruction 01.wav"
                  },
                  {
                    "type": "MEDIA ITEM",
                    "filename": "Instruction 02.wav"
                  }
                ]
              },
              {
                "type": "REGION",
                "name": "Content",
                "components": [
                  {
                    "type": "MEDIA ITEM",
                    "filename": "Content 01.wav"
                  },
                  {
                    "type": "MEDIA ITEM",
                    "filename": "Content 02.wav"
                  }
                ]
              }
            ]
          },
          {
            "type": "REGION",
            "name": "TRACK - Track 01",
            "components": [ ... ]
          }
        ]
      },
      {
        "type": "REGION",
        "name": "DISC - Disc 02",
        "components": [ ... ]
      }
    ]
  }
  ```

  ### JSON objects

  There are only 2 basic JSON object types:

  * `REGION`
  * `MEDIA ITEM`

  #### REGION

  A `REGION` is used to _wrap_ and _contain_ a series of _components_.

  Here are the valid members of a `REGION` object:

  * `type` (string) (__required__) : This _must_ be "REGION" in order to be
    interpreted properly.
  * `name` (string) (optional) : If defined, the _REAPER Region_ will be named
    "[name]"
  * `track` (string) (optional) : If specified, all components will be added to this
    track, unless overridden. If not, the _inherited_ track will be used. If there
    is no _inherited_ track, a track with no name will be used.
  * `path` (string) (optional) : If specified, all components' paths will be
    relative to this path. If not, the _inherited_ path will be used.  If there is
    no _inherited_ path, the root path will be used. The root path is the
    location of the JSON file itself.
  * `components` (array) (optional) : If defined, the objects _within_ the array
    will be interpreted and imported into this `REGION`. If empty or
    undefined, the `REGION` will have length 0.

  Here's an example `REGION` with all the bells and whistles:

  ```
  {
    "type": "REGION",
    "name": "Super Duper Region",
    "track": "Cowbell",
    "path": "clips/percussion/cowbell/",
    "components": [...]
  }
  ```

  For `REGION` objects, __Clip Splicer__ will:

  1. Start a _REAPER region_ at the beginning of the object.
  1. Render all of the _components_ within the object in their proper sequence.
  1. End the _REAPER region_ at the end of the last _component_.

  #### MEDIA ITEM

  A `MEDIA ITEM` is used to represent an _audio file_ or _period of silence_.

  Here are the valid member of a `MEDIA ITEM` object:

  * `type` (string) (__required__) : This _must_ be "MEDIA ITEM" in order to be
    interpreted properly.
  * `name` (string) (optional) : If defined, the _REAPER Media Item_ will be named
    "[name]".
  * `track` (string) (optional) : If specified, this _REAPER Media Item_ will be
    added to this track. If not, the _inherited_ track will be used. If there
    is no _inherited_ track, a track with no name will be used.
  * `filename` (string) (optional) : If specified, __Clip Splicer__ will look for a
    file with the specified filename, relative to the path, and place it in the
    _REAPER Media Item_. If not, an empty _REAPER Media Item_ will be used.
  * `length` (number) (optional) : If specified, the _REAPER Media Item_ will use
    the specified length (in seconds). If not, the file's original length will be
    used. If the specified length is _shorter_ than the file's length, the end of
    the file will be truncated. If the specified length is _longer_ than the
    file's length, the audio will be looped to reach the length.
  * `mute` (true/false) (optional) : If true, the _REAPER Media Item_ will be muted.

  Here's an example `MEDIA ITEM` with all the bells and whistles.

  ```
  {
    "type": "MEDIA ITEM",
    "name": "Super Duper Item",
    "track": "Aux. Percussion",
    "filename": "TheFever.wav",
    "length": 1000,
    "mute": true
  }
  ```

  ### path

  If an object specifies a `path`, all internal components within
  that `REGION` will _inherit_ the specified `path`. Internal components
  can _extend_ their parent's path by specifying a new `path`.
Author: beaunus
Licence: GPL v3
Provides:
    beaunus_Clip_Splicer/example/*.json
    beaunus_Clip_Splicer/schema/*.json
REAPER: 5.0
Version: 2.0

Changelog:
v1.0 (2017-02-22)
    + Initial Release
v2.0 (2017-09-03)
    + Simplify JSON specification
    + Add nested regions
    + Add region names
    + Add mute
"""

import datetime
import json
import os

# A mapping of (string)->(int) for looking up trackidx
tracks = dict()

missing_files = dict()


def add_file_to_missing_file_list(filename, reaper_media_track):
    """Adds the specified file to the missing files register.

    The missing files are sorted by the reaper_media_track on which they should
    appear.

    Args:
        filename: The missing file's name
        reaper_media_track: The track that the missing file should go on.
    """
    track_name = RPR_GetSetMediaTrackInfo_String(reaper_media_track, "P_NAME",
                                                 None, False)[3]
    if track_name not in missing_files:
        missing_files[track_name] = list()
    if filename not in missing_files[track_name]:
        missing_files[track_name].append(filename)


def load_file(filename):
    """Loads the specified file.

    Args:
        filename: The full path to the REAPER Clip Splicer JSON file that should be loaded

    Returns:
        A dictionary object that represents the file.
    """
    # Open the file and load it into an dictionary object.
    file = open(filename, 'r')
    return json.load(file)


def get_trackidx(track_name):
    """Returns the REAPER trackidx for the track with the specified track_name.

    Args:
        track_name: The name of the track whose index should be returned

    Returns:
        The index of the track with the given name
    """
    if track_name in tracks:
        return tracks[track_name]
    # Create a new track and add its mapping to the global variable
    new_trackidx = RPR_GetNumTracks()
    RPR_InsertTrackAtIndex(new_trackidx, True)
    new_track = RPR_GetTrack(0, new_trackidx)
    RPR_GetSetMediaTrackInfo_String(new_track, "P_NAME", track_name, True)
    tracks[track_name] = new_trackidx
    return new_trackidx


def render_empty_midi_item(name, reaper_media_track, length):
    """Renders an empty MIDI item of the specified length in the specified
    track.

    The cursor position will move to the end of the newly created MIDI item.

    Args:
        name: The name that should be given to the MIDI item.
        reaper_media_track: The REAPER media track that the MIDI item should be
        added to.
        length: The length of the MIDI item.
    """
    # Add the MIDI item
    start_time = RPR_GetCursorPosition()
    end_time = start_time + length
    RPR_CreateNewMIDIItemInProj(reaper_media_track, start_time, end_time,
                                False)
    # Get a reference to the newly added MIDI item take
    new_item_index = RPR_GetTrackNumMediaItems(reaper_media_track) - 1
    reaper_media_item = RPR_GetTrackMediaItem(reaper_media_track,
                                              new_item_index)
    reaper_take = RPR_GetActiveTake(reaper_media_item)
    # Adjust the name of the MIDI item, if necessary
    if name is not None:
        RPR_GetSetMediaItemTakeInfo_String(reaper_take, "P_NAME", name, True)
    # Move the cursor to the end of the newly created MIDI item
    RPR_SetEditCurPos(end_time, True, False)


def render_file(filename, path, name, reaper_media_track, length, mute):
    """Renders an audio file in the specified track.

    The cursor position will move to the end of the newly created media item.

    Args:
        filename: The filename for the file to be loaded.
        path: The location of the file.
        name: The name that should be applied to the REAPER media item take.
        reaper_media_track: The track that the audio file should be put on.
        length: If specified, the desired length of the media item. If not
        specified, the default length of the audio.
        mute: Whether or not the media item should be muted
    """
    if path is not None:
        full_filename = os.path.join(path, filename)
    else:
        full_filename = filename
    # Add the audio file if the full_filename is valid
    if RPR_file_exists(full_filename):
        # Add the media to the track
        RPR_SetOnlyTrackSelected(reaper_media_track)
        cursor_position_before = RPR_GetCursorPosition()
        RPR_InsertMedia(full_filename, 0)
        # Get a reference to the recently added take
        new_item_index = RPR_GetTrackNumMediaItems(reaper_media_track) - 1
        reaper_media_item = RPR_GetTrackMediaItem(reaper_media_track,
                                                  new_item_index)
        reaper_take = RPR_GetActiveTake(reaper_media_item)
        # Adjust the name of the newly created media item, if necessary
        if name is not None:
            RPR_GetSetMediaItemTakeInfo_String(reaper_take, "P_NAME", name,
                                               True)
        # Adjust the length of the newly created media item, if necessary
        if length is not None:
            RPR_SetMediaItemLength(reaper_media_item, length, False)
            RPR_SetEditCurPos(cursor_position_before + length, True, False)
        # Mute the newly created media item, if necessary
        if mute:
            RPR_SetMediaItemInfo_Value(reaper_media_item, "B_MUTE", True)
    # If the file doesn't exist, add an empty MIDI item in its place
    else:
        if name is None:
            name = ""
        render_empty_midi_item(name + " MISSING " + filename,
                               reaper_media_track, 10)
        add_file_to_missing_file_list(filename, reaper_media_track)


def render_media_item(media_item, path=None, track=None):
    """Render the specified media item.

    The rendering process depends on the media item's type.
    The cursor position is moved to the end of the newly created media item.

    Args:
        media_item: The media item to render.
        path: The path that all filenames will be relative to.
        track: The track that the media item should be put on.
    """
    # Initialize media_item specific variables
    if "name" in media_item:
        name = media_item["name"]
    else:
        name = None
    if "track" in media_item:
        track = media_item["track"]
    if "filename" in media_item:
        filename = media_item["filename"]
    else:
        filename = None
    if "length" in media_item:
        length = media_item["length"]
    else:
        length = None
    if "mute" in media_item:
        mute = media_item["mute"]
    else:
        mute = False
    # Get the REAPER media_track for this media_item
    reaper_media_track = RPR_GetTrack(0, get_trackidx(track))
    # Render the media item, based on whether or not there is a filename
    if filename is not None:
        render_file(filename, path, name, reaper_media_track, length, mute)
    else:
        render_empty_midi_item(name, reaper_media_track, length)


def render_region(region, path=None, track=None):
    """Render the specified region and all of its components.

    Args:
        region: The region to be rendered.
        path: The path that all filenames should be relative to.
        track: The track that all components should be added to, unless
        overridden.
    """
    # Store the position for this start of this region
    cursor_position_before = RPR_GetCursorPosition()
    # Render the components in this region
    if "components" in region:
        for component in region["components"]:
            render_component(component, path, track)
    # Determine the name for this region
    if "name" in region:
        name = region["name"]
    else:
        name = ""
    # Add the region to the project
    RPR_AddProjectMarker(0, True, float(cursor_position_before),
                         float(RPR_GetCursorPosition()),
                         name, 0)
    RPR_UpdateTimeline()


def render_component(component, path=None, track=None):
    """Render the specified component, based on it's type.

    Args:
        component: The component to be rendered.
        path: The path that all filenames should be relative to.
        track: The track that all components should be added to, unless
        overridden.
    """
    if component["type"] == "REGION":
        render_region(component, path, track)
    if component["type"] == "MEDIA ITEM":
        render_media_item(component, path, track)


def generate_missing_file_report(directory):
    """Generates a txt file report of all the missing files for this project.

    Arg:
        directory: The directory that the report should be put it
    """
    report_filename = os.path.join(directory, 'REAPER Clip Splicer report ' +
                                   str(datetime.datetime.now()) + ".txt")
    report_file = open(report_filename, "w")
    report_string = ""
    report_string += "REAPER Clip Splicer report\n"
    report_string += str(datetime.datetime.now()) + "\n\n"
    report_string += "MISSING Files\n\n"
    for track in missing_files:
        report_string += track + "\n\n"
        for missing_filename in missing_files[track]:
            report_string += missing_filename + "\n"
        report_string += "\n"
    report_file.write(report_string)


def main():
    """Execute the script.
    """
    RPR_Undo_BeginBlock()
    # Prompt the user for the JSON file that describes the Clip Splicer project
    filename = RPR_GetUserFileNameForRead(None, None, ".json")[1]
    directory = os.path.dirname(filename)
    # If a file is selected, load and render it
    if filename != None:
        specification = load_file(filename)
        # Determine the path for audio files in this Clip Splicer project
        root_folder = os.path.dirname(os.path.realpath(filename))
        if "path" in specification:
            path = os.path.join(root_folder, specification["path"])
        else:
            path = root_folder
        # Render the components
        for component in specification["components"]:
            render_component(component, path)
    RPR_Undo_EndBlock("Import Clip Splicer JSON file.", 0)
    generate_missing_file_report(directory)

if __name__ == "__main__":
    main()
