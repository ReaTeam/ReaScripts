try:
    import tkinter
except ImportError:
    pass
try:
    import pickle
except ImportError:
    pass
try:
    import debug
except ImportError:
    pass
try:
    import os
except ImportError:
    pass
try:
    import sys
except ImportError:
    pass

class RSStateManager(object):
    '''
    Saves and recalls settings.

    To Use:
    Set RSStateManager.appname
    Then call stateManager_Start with name of section of app and dictionary
    we want saved and recalled.  This will populate the dict with the saved
    dict entries.
    With newControlIntVat andnewControlStrVar return new variables that are
    managed in the dictionary for attaching to controls, or anything else.
    Settings are automatically saved.
    '''
    appname = ""

    def stateManager_Start(self, name, dictionary):
        self.__name = name
        self.__statedict = dictionary
        self.__get()

    def newControlIntVar(self, dictName, default=1):
        intv = tkinter.IntVar()
        if dictName in self.__statedict:
            intv.set(self.__statedict[dictName])
        else:
            intv.set(default)
        intv.trace("w", lambda name, index, op,
                    dictName=dictName: self.__updateSettings(dictName, intv))
        return intv

    def newControlStrVar(self, dictName, default=""):
        strv = tkinter.StringVar()
        if dictName in self.__statedict:
            strv.set(self.__statedict[dictName])
        else:
            strv.set(default)
        strv.trace("w", lambda name, index, op,
                    dictName=dictName: self.__updateSettings(dictName, strv))
        return strv

    def __updateSettings(self, key, controlVar):
        debug.msg("Key = " + key)
        debug.msg("Value = " + str(controlVar.get()))
        debug.msg("In Dict: "+key+"  "+str(controlVar.get()))
        self.__statedict[key] = controlVar.get()

    def __get(self):
        path = os.path.join(sys.path[0], (RSStateManager.appname + self.__name + ".ini"))
        if os.path.isfile(path):
            file = open(path, "rb")
            d = pickle.load(file)
            debug.msg(d)
            self.__statedict = d
            file.close()
        else:
            self.__set()

    def __set(self):
        path = os.path.join(sys.path[0], (RSStateManager.appname + self.__name + ".ini"))
        file = open(path, "wb")
        pickle.dump(self.__statedict, file)
        file.close()
    #save settings on exit
    def __del__(self):
        self.__set()

