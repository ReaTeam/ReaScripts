try:
    from reaper_python import *
except ImportError:
    pass

debug = False

def msg(m):
    if (debug):
        RPR_ShowConsoleMsg(str(m)+'\n')