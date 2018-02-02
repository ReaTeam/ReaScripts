#! /usr/local/bin/python3
# coding=utf-8
"""A utility module for beaunus_clip_splicer.
"""

TRACK_INDEX = None


def make_generic_dict(args):
    """Given a list of arguments, returns a dictionary with each argument as a
    properties in the dictionary.

    Args:
        args: A list of arguments that will become properties in the dictionary.

    Returns:
        A dictionary containing all the data in the arguments.
    """
    result = dict()
    for key in args:
        if args[key]:
            result[key] = args[key]
    return result


# pylint: disable=unused-argument
def make_media_item(name=None,
                    track=None,
                    filename=None,
                    length=None,
                    mute=False):
    """Returns a dictionary that represents a media item.

    Args:
        name: The name of the media item.
        track: The track that the media item should appear on.
        filename: The file that should be loaded into the media item.
        length: The length of the media item.
        mute: Whether or not to mute the media item.

    Returns:
        A dictionary that represents the media item.
    """
    result = make_generic_dict(locals())
    result['type'] = 'MEDIA ITEM'
    return result


# pylint: disable=unused-argument
def make_region(name=None, track=None, path=None, components=None):
    """Returns a dictionary that represents a region.

    Args:
        name: The name of the region.
        track: The track that all children should appear on.
        path: The path that all children's files exist in.
        components: The components that should be loaded into the region.

    Returns:
        A dictionary that represents the region.
    """
    result = make_generic_dict(locals())
    result['type'] = 'REGION'
    if not components:
        result['components'] = list()
    return [result, result['components']]


# pylint: disable=global-statement
def make_track(name, pre_track_pause_length=0):
    """Returns a new track and a reference to the track's components.

    Args:
        name: The name of the track.

    Returns:
        A list containing a single empty track.
    """
    result = list()

    global TRACK_INDEX
    if TRACK_INDEX is None:
        TRACK_INDEX = 1

    track_name = 'Track ' + str(TRACK_INDEX).zfill(2) + ' - ' + name
    [main_region, components] = make_region(track_name)
    TRACK_INDEX += 1
    result.append(main_region)
    components.append(
        make_media_item(
            'PAUSE at beginning of track',
            'PAUSES',
            length=pre_track_pause_length))

    return [result, components]
