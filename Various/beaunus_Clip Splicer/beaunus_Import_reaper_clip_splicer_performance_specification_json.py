# pylint: disable=trailing-whitespace
# pylint: disable=invalid-name
# TODO: What are the repeats NOT the same length as the previous item?
"""
ReaScript Name: Import Clip Splicer JSON file
About:
    This module imports a Clip Splicer JSON file
Author: beaunus
Licence: GPL v3
REAPER: 5.0
Version: 1.0

Changelog:
v1.0 (2017-02-22)
    + Initial Release
"""

import datetime
import json
import os
import inspect

# pylint: disable=pointless-string-statement
# pylint: disable=undefined-variable

# A mapping of (string)->(int) for looking up trackidx
tracks = dict()


def load_file(filename):
    """Loads the specified file.

  Args:
      filename: The full path to the REAPER Clip Splicer JSON file that should
      be loaded

  Returns:
      A dictionary object that represents the file.
  """
    # Open the file and load it into an dictionary object.
    file = open(filename, 'r')
    root_folder = os.path.dirname(filename)
    # Parse the JSON file into an object
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
    RPR_ShowConsoleMsg("Adding track [" + track_name + "]")
    new_trackidx = RPR_GetNumTracks()
    RPR_InsertTrackAtIndex(new_trackidx, True)
    new_track = RPR_GetTrack(0, new_trackidx)
    RPR_GetSetMediaTrackInfo_String(new_track, "P_NAME", track_name, True)
    tracks[track_name] = new_trackidx
    return new_trackidx


def render_empty_midi_item(name, reaper_media_track, length):
    start_time = RPR_GetCursorPosition()
    end_time = start_time + length
    RPR_CreateNewMIDIItemInProj(reaper_media_track, start_time, end_time,
                                False)
    new_item_index = RPR_GetTrackNumMediaItems(reaper_media_track) - 1
    reaper_media_item = RPR_GetTrackMediaItem(reaper_media_track,
                                              new_item_index)
    reaper_take = RPR_GetActiveTake(reaper_media_item)
    if name is not None:
        RPR_GetSetMediaItemTakeInfo_String(reaper_take, "P_NAME", name, True)
    RPR_SetEditCurPos(end_time, True, False)


def render_file(filename, name, reaper_media_track, length, mute):
    if (RPR_file_exists(filename)):
        RPR_SetOnlyTrackSelected(reaper_media_track)
        cursor_position_before = RPR_GetCursorPosition()
        RPR_InsertMedia(filename, 0)
        new_item_index = RPR_GetTrackNumMediaItems(reaper_media_track) - 1
        reaper_media_item = RPR_GetTrackMediaItem(reaper_media_track,
                                                  new_item_index)
        reaper_take = RPR_GetActiveTake(reaper_media_item)
        if name is not None:
            RPR_GetSetMediaItemTakeInfo_String(reaper_take, "P_NAME", name,
                                               True)
        if length is not None:
            RPR_SetMediaItemLength(reaper_media_item, length, False)
            RPR_SetEditCurPos(cursor_position_before + length, False, False)
        if mute == True:
            RPR_SetMediaItemInfo_Value(reaper_media_item, "B_MUTE", True)
    else:
        render_empty_midi_item(name + " MISSING " + filename,
                               reaper_media_track, 10)


def render_media_item(media_item, path=None, track=None):
    # RPR_ShowConsoleMsg("MEDIA ITEM")
    # Initialize media_item specific
    # variables
    if "name" in media_item:
        name = media_item["name"]
    else:
        name = None
    if "track" in media_item:
        track = media_item["track"]
    if "filename" in media_item:
        filename = media_item["filename"]
        if path is not None:
            RPR_ShowConsoleMsg("path => " + path + "\n")
            filename = os.path.join(path, filename)
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
    if filename is not None:
        render_file(filename, name, reaper_media_track, length, mute)
    else:
        render_empty_midi_item(name, reaper_media_track, length)


def render_region(region, path=None, track=None):
    if "components" in region:
        for component in region["components"]:
            render_component(component, path, track)


def render_component(component, path=None, track=None):
    if component["type"] == "REGION":
        render_region(component, path, track)
    if component["type"] == "MEDIA ITEM":
        render_media_item(component, path, track)


def main():
    """Execute the script.
    """
    # Prompt the user for the JSON file that describes the disc
    # layout
    filename = RPR_GetUserFileNameForRead(None, None, ".json")[1]

    if filename != None:
        specification = load_file(filename)
        root_folder = os.path.dirname(os.path.realpath(filename))
        if "path" in specification:
            path = os.path.join(root_folder, specification["path"])
        else:
            path = root_folder

        for component in specification["components"]:
            render_component(component, path)


if __name__ == "__main__":
    main()
