@description Link FX chains of 2 different tracks (GUI)
@author Marini Mattia
@version 1.0
@metapackage
@provides
  [main] Marini_FX linker/Marini_FX linker background tasks.lua
  [main] Marini_FX linker/Marini_FX linker toggle autostart.lua
  [main] Marini_FX linker/Marini_FX linker toggle UI.lua
@about
  ### A GUI based lua script to link FX parameters across different tracks
  This plugin runs a backgound task that links the selected tracks, ensuring that the plugin configurations of the 2 FX chains match

  _A full Guide can be found [here](https://github.com/mattia-marini/ReaperLink/blob/main/Guide.pdf)_

  #### Usage:
  - Run _"Marini_FX linker background tasks"_ or configure automatic startup (see below)
  - Toggle Ui with _"Marini_FX linker toggle UI.lua"_ to create/remove links

  #### Features: 
  - Linking **every** parameters of **every** plugin across different tracks
  - Linking state is saved on project basis
  - GUI based link managment
  - Multiple tabs support and hot project reloading
  - Flexible and roboust linking
  - **Zero dependency script**

  #### Automatic startup:
  In order for the script to work, a background task should be running i.e., to make synching happen, you have to run the "Marini_FX linker background tasks" script every time you open Reaper. To make that happen automatically you can run the "Marini_FX linker toggle autostart". (you can see a script state next to its description in action list. Once set to on, the script will automatically launch on next startup)

