"""
ReaScript Name: Import Clip Splicer Performance Specification JSON file
About: 
  # beaunus REAPER Clip Splicer
  
  This module imports a _performance specification_ JSON document into the 
  current REAPER session.
  
  The project was created for making _listen and repeat_-style CDs for a 
  language school.  In such CD projects, there are hundreds of audio clips 
  that need to be aligned and sorted by track.  This automated process saves 
  most of the time needed for producing the CDs.
  
  ## Define the _performance specification_
  
  Use a Google Sheet to define the discs and tracks.
  
  https://docs.google.com/spreadsheets/d/1FlhfMCX0HRUWVk8Or2GJZTPwxc_uaci3KM-0VbspnIY/edit#gid=0
  
  ### Understanding the JSON representation
  
  The specification is represented by a dictionary.
  
      {
        // Disc 01
        "Disc_01 Title": [
          null, // CD Track 00 is irrelevant.
          // Track 01
          [
            "Track_01 Component_01",
            ...,
            "Track_01 Component_N"
          ],
          ...,
          // Track N
          [
            "Track_N Component_01",
            ...,
            "Track_N Component_N"
          ]
        ],
        ...,
        // Disc N
        "Disc_N Title": [
          null, // CD Track 00 is irrelevant.
          // Track 01
          [
            "Track_01 Component_01",
            ...,
            "Track_01 Component_N"
          ],
          ...,
          // Track N
          [
            "Track_N Component_01",
            ...,
            "Track_N Component_N"
          ]
        ],
      }
  
  ### Adding templates
  
  The real power of the spreadsheet is creating _templates_.  A _template_ 
  uses a custom Google Apps Script to create an array of components, given a 
  simple set of template arguments.
  
  Here's an example of a template from the spreadsheet.
  
  <table>
      <tr>
          <th>Disc</th>
          <th>Track</th>
          <th>Component</th>
          <th>Performer</th>
          <th>Template</th>
          <th>Template Parameters</th>
          <th>Template Arguments</th>
      </tr>
      <tr>
          <td>My Amazing Disc</td>
          <td>1</td>
          <td></td>
          <td></td>
          <td>Repeat Words</td>
          <td>
              performer (string)<br/>
              word (string)<br/>
              num_repetitions (int)
          </td>
          <td>
              John Lennon<br/>
              Love<br/>
              3
          </td>
      </tr>
  </table>
  
  In order to interpret the above data, you will need to adjust the 
  spreadsheet's `templates.gs` script in the following ways:
  
  1. In the function `template()`, add a case for the template `"Repeat Words"`.
  1. Add a function `templateRepeatWords()`.
  
  The function should return an array of components.  For example:
  
      [
        "Love [John Lennon]",
        "_PAUSE_AFTER_PAGE_NUMBER",
        "Love [John Lennon]",
        "_PAUSE_AFTER_PAGE_NUMBER",
        "Love [John Lennon]",
        "_PAUSE_AFTER_PAGE_NUMBER"
      ]
  
  ## Import the specification into a REAPER session.
  
  1. Run the script `Script: beaunus_import_reaper_clip_splicer_json.py`
  1. Select a .json file that contains a REAPER Clip Splicer specification.
  1. Examine the generated report to see what needs to be recorded.
      - The report can be found in the same folder as the .json file.
  
  ## Record the clips
  
  1. If the _performance sequence_ is simple enough to manually trim each clip,
  simply record the clips without a lyrics track.
  1. If you want to automated the trimming process:
      1. Import the _performance sequence_ into a lyrics track in a REAPER
      session.
      1. Set a reasonable tempo.
      1. Record the clips in order.
  
  ## Trim and save the clips
  
  Performances should be __loudness normalized__ to -23LUFS.
  
  If you have used a lyrics track:
  
  1. Convert the lyrics to markers.  
    + `beaunus_Add markers for lyrics in selected items.lua`
  1. Split the performance using dynamic split.
  1. Trim silence at the beginnings and ends of clips.
  1. Name the takes according to the marker that cuts them.  
    + `beaunus_Name item takes by last marker to cut item.lua`
  1. SWS: Create regions from selected items (name by active take)
  1. Render regions.
  
  Finished clips should be named according to the following convention:
  
  `[label] [[performer]].[file extension]`
  
  `$region [$track]`
  
  For example:
  
  `Love [John Lennon].wav`
  
  Clips should be put in the folder `"clips"` relative to the .json file.
  
  After all the clips have been recorded, you can again 'Import the 
  specification into a REAPER session.'
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

# pylint: disable=pointless-string-statement
# pylint: disable=undefined-variable
def get_performer(component_string):
    """Returns the performer of the specified component.

    Args:
        component_string: The JSON representation of the component.
                For example: "Apple [Beau]"
    Returns:
        The performer of the component. For example: "Beau"
    """
    index_of_open = component_string.find("[")
    index_of_close = component_string.find("]", index_of_open)
    performer = component_string[index_of_open + 1:index_of_close]
    return performer


def component_key(component_string):
    """Returns a key for a component string.

    The key is the performer's name, followed by the component string itself.
    """
    return get_performer(component_string) + component_string


class ReaperClipSplicer:
    """A class to represent a REAPER clip splicer project.

    Clips are searched for in the "clips" folder, relative to the location of
    the selected .json file.

    Reports are generated in the same folder as the selected .json file.

    Attributes:
        media_tracks: REAPER MediaTracks to be used for components.
                Indexed by performer name.
        pause_lengths: Times to pause between certain component types.
                Indexed by pause_length name.
        discs: Disc specifications.  Indexed by disc name.
        available_files: Files that correspond to specified components.
        unavailable_files: Files that are unavailable for the project.
        folder: The folder in which the JSON file is found.
    """

    def __init__(self, specification, folder):
        """Initializes a new ReaperClipSplicer project.
        """
        self.media_tracks = dict()
        self.pause_lengths = dict()
        self.discs = specification
        self.available_files = set()
        self.unavailable_files = set()
        self.folder = folder

        self.initialize_pause_lengths()

    def initialize_pause_lengths(self):
        """Determine pauses that need to be specified/
        """
        # Iterate over each disc
        # pylint: disable=too-many-nested-blocks
        for disc_val in self.discs.values():
            # Iterate over each track
            for track in disc_val:
                # Iterate over each component
                if track is not None:
                    for component in track:
                        if component.startswith("_PAUSE"):
                            if component not in self.pause_lengths:
                                self.pause_lengths[component] = None

        # Prompt user for pause lengths
        num_pauses = len(self.pause_lengths)
        captions_csv = ','.join(self.pause_lengths.keys())
        retvals_csv = ','.join(list(["1"] * num_pauses))

        user_lengths = RPR_GetUserInputs("Specify Pauses",
                                         num_pauses,
                                         captions_csv,
                                         retvals_csv,
                                         99)[4].split(",")
        i = 0
        for pause_name in self.pause_lengths:
            self.pause_lengths[pause_name] = int(user_lengths[i])
            i += 1

    def get_track(self, track_id):
        """Returns the track object with the specified id.

        If the track_objects array doesn't already contain the specified track,
        add a new track with the given track_id and add it to the track_objects
        array.
        Otherwise, simply return the track object.

        Args:
            track_id: The identifier for the track.

        Returns:
            The REAPER MediaTrack object that represents the track with
            the specified identifier.
        """
        if track_id not in self.media_tracks:
            # Create a new track.
            track_index = RPR_GetNumTracks()
            RPR_InsertTrackAtIndex(track_index, False)
            new_track = RPR_GetTrack(0, track_index)

            # Add the new track to the track_objects array.
            self.media_tracks[track_id] = new_track

            # Name the track according to the track_id.
            RPR_GetSetMediaTrackInfo_String(
                new_track, "P_NAME", track_id, True)

            # Update the UI
            RPR_TrackList_AdjustWindows(True)
            RPR_UpdateTimeline()
        return self.media_tracks[track_id]

    def add_pause(self, component, cursor_position):
        """Add the pause specified in the given component to the session.

        Args:
            component: The JSON representation of the component.
            cursor_position: The starting position of the component.

        Returns:
            A tuple containing the following:
                cursor_position: The new cursor position, after adding
                        the component.
                new_item: The new REAPER MediaItem that represents the newly
                        added component.
        """
        # Get the REAPER MediaTrack for pauses.
        pause_track = self.get_track("_PAUSE")

        # Add a new item to the pause_track.
        new_item = RPR_AddMediaItemToTrack(pause_track)

        # Determine the length of the pause.
        if self.pause_lengths is not None and component in self.pause_lengths:
            RPR_SetMediaItemInfo_Value(
                new_item, "D_LENGTH", self.pause_lengths[component])
        else:
            RPR_SetMediaItemInfo_Value(new_item, "D_LENGTH", 1)

        # Put the newly created pause in place,
        # add it to a new take on the pause track,
        # and name it according to the component specification.
        RPR_SetMediaItemInfo_Value(new_item, "D_POSITION", cursor_position)
        RPR_AddTakeToMediaItem(new_item)
        this_take = RPR_GetActiveTake(new_item)
        RPR_GetSetMediaItemTakeInfo_String(
            this_take, "P_NAME", component, True)

        # Increment the cursor_position and return
        cursor_position += RPR_GetMediaItemInfo_Value(new_item, "D_LENGTH")
        return (cursor_position, new_item)

    def add_repeat(self, cursor_position, prev_item):
        """Adds a repeat specified by the given component to the session.

        Args:
            cursor_position: The starting position of the component.
            prev_item: The previous REAPER MediaItem.

        Returns:
            A tuple containing:
                cursor_position: The new cursor position, after adding the
                        component.
                new_item: The new RPR_MediaItem that represents the newly added
                        component.
        """
        # Get the RPR_MediaTrack for repeats.
        repeat_track = self.get_track("_REPEAT")

        # Add a new item to the repeat_track.
        new_item = RPR_AddMediaItemToTrack(repeat_track)

        # Determine the previous item's length and name.
        prev_item_length = RPR_GetMediaItemInfo_Value(prev_item, "D_LENGTH")
        prev_item_name = \
            RPR_GetSetMediaItemTakeInfo_String(RPR_GetActiveTake(prev_item),
                                               "P_NAME", None, False)[3]
        # Set the repeat item's attributes and add a new take.
        RPR_SetMediaItemInfo_Value(new_item, "D_LENGTH", prev_item_length)
        RPR_SetMediaItemInfo_Value(new_item, "D_POSITION", cursor_position)
        RPR_SetMediaItemInfo_Value(new_item, "B_MUTE", True)
        RPR_AddTakeToMediaItem(new_item)

        # Add the previous item's source to this one.
        this_take = RPR_GetActiveTake(new_item)
        RPR_GetSetMediaItemTakeInfo_String(
            this_take, "P_NAME", prev_item_name, True)
#         prev_take = RPR_GetActiveTake(prev_item)
#         prev_source = RPR_GetMediaItemTake_Source(prev_take)
#         RPR_SetMediaItemTake_Source(this_take, prev_source)

        # Increment the cursor_position.
        cursor_position += RPR_GetMediaItemInfo_Value(new_item, "D_LENGTH")

        return (cursor_position, new_item)

    def add_clip(self, component, cursor_position):
        """Adds the specified clip to the session.

        Args:
            component: The JSON representation of the clip.
            cursor_position: The starting position of the component.

        Returns:
            A tuple containing:
                cursor_position: The new cursor position, after adding the
                        component.
                new_item: The new REAPER MediaItem that represents the newly
                        added component.
        """
        # Determine the performer of the clip.
        performer = get_performer(component)

        # Get the track that the clip should be inserted into.
        track = self.get_track(performer)
        new_item = RPR_AddMediaItemToTrack(track)

        # Determine if the specified file exists.
        filename = self.folder + "/clips/" + component + ".wav"
        file_exists = RPR_file_exists(filename)
        if file_exists:
            self.available_files.add(component + "\n")
            # Select the proper track.
            RPR_SetOnlyTrackSelected(track)
            # Insert the media
            RPR_InsertMedia(filename, 0)
            cursor_position = RPR_GetCursorPosition()
            new_item = RPR_GetSelectedMediaItem(
                0, RPR_CountSelectedMediaItems(0) - 1)
        else:
            self.unavailable_files.add(component + "\n")
            # Set the length and position of the new RPR_MediaItem
            RPR_SetMediaItemInfo_Value(new_item, "D_LENGTH", 1)
            RPR_SetMediaItemInfo_Value(new_item, "D_POSITION", cursor_position)

            # Add a RPR_Take to the new media item.
            RPR_AddTakeToMediaItem(new_item)

            # Increment the cursor_position.
            cursor_position += RPR_GetMediaItemInfo_Value(new_item, "D_LENGTH")

        # Name the take according to the component.
        this_take = RPR_GetActiveTake(new_item)
        RPR_GetSetMediaItemTakeInfo_String(
            this_take, "P_NAME", component, True)

        return (cursor_position, new_item)

    def render_components(self, cursor_position):
        """Render the components of the specified discs into the active REAPER
        project.

        Args:
            cursor_position: The starting position of the rendering.
        """
        # Iterate over each disc
        # pylint: disable=unused-variable
        for disc_name, disc_val in self.discs.iteritems():
            beginning_of_disc = cursor_position
            # Iterate over each track
            track_index = 1
            for track in disc_val:
                beginning_of_track = cursor_position
                prev_item = None
                # Iterate over each component
                if track is not None:
                    for component in track:
                        (cursor_position, prev_item) = \
                            self.add_component(
                                component, cursor_position, prev_item)
                        RPR_SetEditCurPos(cursor_position, False, False)
                    track_region_color = RPR_ColorToNative(
                        255, 0, 255) | 0x1000000
                    RPR_AddProjectMarker2(
                        0,
                        True,
                        beginning_of_track,
                        cursor_position,
                        "TRACK " + str(track_index),
                        0,
                        track_region_color)
                    track_index += 1
            disc_region_color = RPR_ColorToNative(255, 255, 0) | 0x1000000
            RPR_AddProjectMarker2(
                0,
                True,
                beginning_of_disc,
                cursor_position,
                "DISC " + disc_name,
                0,
                disc_region_color)

    def add_component(self, component, cursor_position, prev_item):
        """Adds the specified component to the session.

        Args:
            component: The JSON representation of the component.
            cursor_position: The starting position of the component.

        Returns:
            A tuple containing:
                cursor_position: The new cursor position, after adding the
                    component.
                new_item: The new REAPER MediaItem that represents the newly
                    added component.
        """
        # If this component is a _PAUSE, add an empty item to represent it.
        if component.startswith("_PAUSE"):
            (cursor_position, new_item) = \
                self.add_pause(component, cursor_position)
        # If this component is a _REPEAT, add a muted copy of the previous item
        # to represent it.
        elif component == "_REPEAT_PREVIOUS_WORD":
            (cursor_position, new_item) = self.add_repeat(
                cursor_position, prev_item)
        # Otherwise, add the performed clip to the session.
        else:
            (cursor_position, new_item) = self.add_clip(
                component, cursor_position)
        return (cursor_position, new_item)

    def generate_report(self):
        """Creates a file that reports the available and unavailable files
        for the project.
        """
        # Export the report of available and unavailable files
        now = str(datetime.datetime.now())
        report_file = open(
            self.folder + "/reaper_clip_splicer_report-" + now + ".txt", "w")
        report_file.write("beaunus REAPER Clip Splicer Report\n")
        report_file.write(now + "\n\n")

        report_file.write("Available components" + "\n")
        report_file.writelines(sorted(self.available_files, key=component_key))
        report_file.write("\n")
        report_file.write("Unavailable components" + "\n")
        report_file.writelines(
            sorted(self.unavailable_files, key=component_key))


def main():
    """Execute the script.
    """
    # Prompt the user for the JSON file that describes the disc layout
    filename = RPR_GetUserFileNameForRead(None, None, ".json")[1]

    if filename != None:
        # Open the file and load it into an dictionary object.
        file = open(filename, 'r')
        folder = os.path.dirname(filename)

        # Parse the JSON file into an object
        specification = json.loads(file.read())

        cursor_position = RPR_GetCursorPosition()

        my_reaper_clip_splicer = ReaperClipSplicer(specification, folder)
        my_reaper_clip_splicer.render_components(cursor_position)
        my_reaper_clip_splicer.generate_report()

if __name__ == "__main__":
    main()
