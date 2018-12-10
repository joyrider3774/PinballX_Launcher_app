# PinballX Launcher app
A PinballX Launcher app to specify parameters for the launched application. 
Defaults to pinball FX3 classic / multiplayer hotseat selection to be controlled by your pinball cabinet contols

![PinballX Launcher app](/images/launcher.png)

## Usage
Place the executable in a directory you can remember and launch it once. Then close the application using esc key or alt + f4. 
It should have created an ini file with the same name as the executable. By default it will generate settings for pinball FX3
to be able to select multiplayer and classic mode options. The app is setup to use ESC as the quit key, 
LEFT SHIFT to select previous button, RIGHT SHIFT to select next button and the RETURN / ENTER key to launch. You should choose the same
keys for this app as the keys you are using in the PinballX frontend. If your cabinet is setup to use different keys, you can edit the 
keys in the ini file under the "SETTINGS" section. You'll need to supply the following entries "LEFTKEY", "RIGHTKEY", "LAUNCHKEY" and "QUITKEY".
These should contain nummerical values of the Virtual Keys (VK_XXX KeyCodes) to be used. If you don't know these values you can use the supplied "Showkeys" tool
to find out these numerical values. You basically start the showkeys app and then press the (same) buttons on your cabinet as the ones that
you use to make selections in the PinballX frontend. Write each numerical value corresponding to the button (key) you pressed on a paper and
add them the to ini file. 

![PinballX Settings](/images/showkeys.png)

You will also need to change your PinballX Settings to start this launcher app instead of Pinball FX3 and supply as 
the parameter needed to launch the selected table. The app expects only one parameter to be given and in Case of Pinball FX3 this is "-table_[TABLEFILE]" including the quotes. 
Extra supplied parameters are ignored

![PinballX Settings](/images/pinballxsetup.png)

once you got everything setup this launcher app will be launched instead of Pinball FX3 directly and you can choose the settings using your cabinet buttons,
the app will then launch pinball fx3 with the correct parameters for your selection. The app is by default setup to rotate itselve 270° that's
basically how i think most cabinets are setup on the playfield, like landscape mode and letting pinballx rotate the screen. if your cabinet,
is already running in portrait mode you need to edit the ini to not let the app rotate itselve. 
The app screen is 800 x 600 default but there are options to increase or decrease this size by scalling it with a multiply and divide value 
to support higher or lower res resolutions, for example if you are using a 4K screen, the app will look small and you should upscale it.

## INI File settings

### LEFTKEY
Specifies the key to be used for left selection (default Left shift = 160)

### RIGHTKEY
Specifies the key to be used for right selection (default right shift = 161)

### LAUNCHKEY
Specifies the key to be used to confirm the selection and launch the app, by default pinball fx3 (default return = 13)

### QUITKEY
Specifies the key to be used for quiting the launcher and returning to PinballX. Please make sure it's set to same key as PinballX's quit key (default esc = 27)

### STARTPARAMS
should contain the launch command to launch the game in case of steam related games the applaunch parameter with appid, can also be empty if you are directly calling an extrnal app, for example one that does not require steam. You can also supply extra parameters here you want to add, for example adding -offline after the steam appid in case of pinball fx3 if you want to run in offline mode  (default = -applaunch 442120 to launch pinball fx3)

### PATH
Path, including filename to launch the game, or in this case steam. The app will by default search for the steam.Exe location in the windows registry, but you can change this to anything you like

### DONTREADSTEAMPATHREG
If the above PATH setting is empty, the app will keep trying to find the steam location using the registry. By setting this value to 0 you can prevent it from doing so. (Default 0)

### SCALEM
To be used along with the SCALED value specifies the value where the forms width and height will be multiplied with. Examples are M=2,D=1 equals double size 200%,  M=3, D=4  equals 3 quarter size 75%, M=5, D=4 (125%) etc (Default 1)  

### SCALED
To be used along with the SCALEM value specifies the value where the forms width and height will be divided with. Examples are M=2,D=1 equals double size 200%,  M=3, D=4  equals 3 quarter size 75%, M=5, D=4 (125%) etc (Default 1)  

### DONTSAVEINIONEXIT
Allows you to prevent writing the ini file, if you want that for some reason. By default read ini settings will always be written again to the ini file on exit. Set this value to 1 if you don't want the tool to remember for example the last selected button (Default = 0)

### LASTACTIVEBUTTON
Used to remember last selected button, will only be written if DONTSAVEINIONEXIT is 0. If you want to specify a specific preference set this to a specific button value (1-12) and set DONTSAVEINIONEXIT to 1

### ROTATE
Specifies the rotation used, 0 = no rotation, 1 = 90° rotation, 2 = 180° rotation, 3 = 270° rotation (Default = 3)

### SMOOTHRESIZEDRAW
When set to 1 will use a resizing function that applies smoothing when SCALED divided by SCALEM does not equal 1 (means form is resized). This will make sure text is not jaggy and smoothend on the scaled bitmap. When this value is 0 a faster function is used but quality will be reduced (Default = 1)

### TITLE
Title to be shown at the top of the program (Default = Pinball FX3 Launcher)

## ADVANCED INI SETTINGS
If you make a copy of the executable and rename it and then start it again a seperate ini file will be created (same name as binary) using  same 
default settings above, you can then use the following section to change the behaviour of this app to be used with other games than the 
default Pinball FX3 settings or even outside pinballx. For example if you have other apps that can use parameter sets you like to select. You can configure
up to 12 buttons each with it's own parameters. Each Button section consits of 3 values to be specifed..

### TEXT
Specifies the text to be shown on the button, this will be word and letter wrapped as well as clipped if the text is too long

### ENABLED
Specifies if the button is enabled / visible to be selected

### PARAM
Specifies the parameter that will be used to launch your application when this button is selected.
