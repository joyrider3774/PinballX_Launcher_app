# Zaccaria Pinball Launcher app

![Zaccaria Pinball Launcher app](/other_games/Zaccaria%20Pinball/launcher.png)

[Latest Release](https://github.com/joyrider3774/PinballX_Launcher_app/releases/latest)

## Usage
Place the executable from the latest release in a directory you can remember, don't launch it yet. Download the [ZaccariaLauncher.ini](/other_games/Zaccaria%20Pinball/ZaccariaLauncher.ini) file
and place it in the same directory as the executable. Then rename the "PinballFX3Launcher.exe" launcher executable to "ZaccariaLauncher.exe" . 
So that you have a ZaccariaLauncher.exe and the downloaded ZaccariaLauncher.ini file in the same directory. Then run the application once and 
immediatly close it close the application using q key or alt + f4. 
It should have updated the ini file with all options and detected your steam installation. The app is setup to use q as the quit key, 
LEFT SHIFT to select previous button, RIGHT SHIFT to select next button and the RETURN / ENTER key to launch. You should choose the same
keys for this app as the keys you are using in the PinballX frontend. If your cabinet is setup to use different keys, you can edit the 
keys in the ini file under the "SETTINGS" section. You'll need to supply the following entries "LEFTKEY", "RIGHTKEY", "LAUNCHKEY" and "QUITKEY".
These should contain nummerical values of the Virtual Keys (VK_XXX KeyCodes) to be used. If you don't know these values you can use the supplied "Showkeys" tool
to find out these numerical values. You basically start the showkeys app and then press the (same) buttons on your cabinet as the ones that
you use to make selections in the PinballX frontend. Write each numerical value corresponding to the button (key) you pressed on a paper and
add them the to ini file. 

![PinballX Settings](/images/showkeys.png)

You will also need to change your PinballX Settings to start this launcher app instead of Zaccaria Pinball and supply as 
parameter the selected table to launch. The app expects only one parameter to be given and in Case of Zaccaria Pinball this is "[TABLEFILE]" including the quotes.

![PinballX Settings](/other_games/Zaccaria%20Pinball/pinballxsetup.png)

once you got everything setup this launcher app will be launched instead of Zaccaria Pinball directly and you can choose the settings using your cabinet buttons,
the app will then launch Zaccaria Pinball with the correct parameters for your selection. The app is by default setup to rotate itselve 270° that's
basically how i think most cabinets are setup on the playfield, like landscape mode and letting pinballx rotate the screen. if your cabinet,
is already running in portrait mode you need to edit the ini to not let the app rotate itselve. 
The app screen is 800 x 600 default but there are options to increase or decrease this size by scalling it with a multiply and divide value 
to support higher or lower res resolutions, for example if you are using a 4K screen, the app will look small and you should upscale it.

## Joystick support
Joystick support is added using NLDJoystick created by Albert de Weerd (aka NGLN) and is by default disabled, if you want to enable it set
USEJOYPAD=1 in the joypad section in the ini file. The default joystick settings are setup to be used with a xbox 360 wireless controller.
You'll need to use the showjoypad tool to show information about your joypad like to find out axis, button presses, POV Movement etc.
be sure to press buttons and move joystick axises etc to find out the settings for the ini file

![showjoypad tool](/images/showjoypad.png)

if the showjoypad tool does not detect your joypad please make sure you have selected your controller to be used as the joypad for older programs and 
also make sure your joypad is attached to your pc before running it. The same applies to the launcher itselve. If it still does not detect it afterwars
it might not be compatible with NLDJoystick. You could however use joytokey tool to map your joypad to keyboard keypresses this launcher will understand

![Control panel joypad Settings](/images/controlpanelcontrollersettings.png)

There are 3 ways to make selections using the joypad. Using POV, buttons or axises and you can disable any of them using the JOYAXISSELECTION,
JOYPOVSELECTION and JOYBUTTONSELECTION settings. You'll also need to specify the LAUNCHBUTTON and QUITBUTTON button

Axises, pov and buttons need to be released before it will register another function so you can not hold left or right to keep moving left or right but
need to move the joypad left, back to center, left again, back to center etc.

## INI File settings

### LEFTKEY
Specifies the key to be used for left selection (default Left shift = 160)

### RIGHTKEY
Specifies the key to be used for right selection (default right shift = 161)

### LAUNCHKEY
Specifies the key to be used to confirm the selection and launch the app, by default pinball fx3 (default return = 13)

### LAUNCHKEY2
Specifies an alternate key to be used to confirm the selection and launch the app, by default pinball fx3 (default space = 32)

### QUITKEY
Specifies the key to be used for quiting the launcher and returning to PinballX. Please make sure it's set to same key as PinballX's quit emulator key (default Q = 81)

### STARTPARAMS
should contain the launch command to launch the game in case of steam related games the applaunch parameter with appid, can also be empty if you are directly calling an extrnal app, for example one that does not require steam. You can also supply extra parameters here you want to add, for example adding -offline after the steam appid in case of pinball fx3 if you want to run in offline mode  (default = -applaunch 442120 to launch pinball fx3)

### PATH
Path, including filename to launch the game, or in this case steam. The app will by default search for the steam.Exe location in the windows registry, but you can change this to anything you like

### DONTREADSTEAMPATHREG
If the above PATH setting is empty, the app will keep trying to find the steam location using the registry. By setting this value to 0 you can prevent it from doing so. (Default 0)

### REPOSITIONWINDOW
When set to 0 will position the window in the center of the screen, when set to 1 will position the window using POSLEFT and POSTOP values on startup. (Default 0)

### POSLEFT
Left postion of the window (seen from top / left point of window). Wil be used as starting position for the left position on startup when REPOSITIONWINDOW equals 1. The window is dragable and will always write the left position of the window upon quiting of the launcher. Values can be negative and they depend on screen setup when using multiple monitors so better use the dragging feature of the window to position where you want it. Dragging is only possible when the program is run outside of pinballx, since pinballx seems to control the mouse when launching the launcher. Using this setting along with POSTOP, you can position the launcher window also on the backglass.

### POSTOP
Top postion of the window (seen from top / left point of window). Wil be used as starting position for the top position on startup when REPOSITIONWINDOW equals 1. The window is dragable and will always write the top position of the window upon quiting of the launcher. Values can be negative and they depend on screen setup when using multiple monitors so better use the dragging feature of the window to position where you want it. Dragging is only possible when the program is run outside of pinballx, since pinballx seems to control the mouse when launching the launcher. Using this setting along with POSLEFT, you can position the launcher window also on the backglass.

### SCALEM
To be used along with the SCALED value specifies the value where the forms width and height will be multiplied with. Examples are M=2,D=1 equals double size 200%, M=3, D=4  equals 3 quarter size 75%, M=5, D=4 (125%) etc (Default 1)  

### SCALED
To be used along with the SCALEM value specifies the value where the forms width and height will be divided with. Examples are M=2,D=1 equals double size 200%,  M=3, D=4  equals 3 quarter size 75%, M=5, D=4 (125%) etc (Default 1)  

### SCALEFONTM
To be used along with the SCALEFONTD value specifies the value where the fonts width and height (actually dpi setting) will be multiplied with. Examples are M=2,D=1 equals double size 200%,  M=3, D=4 equals 3 quarter size 75%, M=5, D=4 (125%) etc (Default 1)  

### SCALEFONTD
To be used along with the SCALEFONTM value specifies the value where the fonts width and height (actually dpi setting) will be divided with. Examples are M=2,D=1 equals double size 200%, M=3, D=4 equals 3 quarter size 75%, M=5, D=4 (125%) etc (Default 1)  

### DONTSAVEINIONEXIT
Allows you to prevent writing the ini file, if you want that for some reason. By default read ini settings will always be written again to the ini file on exit. Set this value to 1 if you don't want the tool to remember for example the last selected button (Default = 0)

### LASTACTIVEBUTTON
Used to remember last selected button, will only be written if DONTSAVEINIONEXIT is 0. If you want to specify a specific preference set this to a specific button value (1-12) and set DONTSAVEINIONEXIT to 1

### ROTATE
Specifies the rotation used, 0 = no rotation, 1 = 90° rotation, 2 = 180° rotation, 3 = 270° rotation (Default = 3)

### SMOOTHRESIZEDRAW
When set to 1 will use a resizing function that applies smoothing when SCALED divided by SCALEM does not equal 1 (means form is resized). This will make sure text is not jaggy and smoothend on the scaled bitmap. When this value is 0 a faster function is used but quality will be reduced (Default = 1)

### FORCEFOREGROUNDWINDOW
Specifies the way the windows is kept in the foreground, 0 = nothing is done to keep window activated, 1 = window is forced to foreground every few milliseconds, 2 = window is forced to foreground once at startup. (Default = 0)

### TITLE
Title to be shown at the top of the program (Default = Pinball FX3 Launcher)

### COLOR1
Color in hexadecimal RGB format for selected button text. (Default = FFFFFF)

### COLOR2
Color in hexadecimal RGB format for not selected button text. (Default = 000000)

### COLOR3
Color in hexadecimal RGB format for title, credits and countdown text. (Default = FFFFFF)

## JOYPAD INI SETTINGS

### USEJOYPAD
enable (1) / Disable (0) joypad support (Default = 0)

### JOYAXISSELECTION
enable (1) / Disable (0) left / right selections using joystick axises, this is tied to LEFTRIGHTAXIS parameter (Default = 1)

### JOYPOVSELECTION
enable (1) / Disable (0) left / right selections using the joysitck pov, this is tied to the JOYPOVLEFTMIN, JOYPOVLEFTMAX, JOYPOVRIGHTMIN and JOYPOVRIGHTMAX parameters (Default = 1)

### JOYBUTTONSELECTION
enable (1) / Disable (0) left / right selections using joystick buttons, this is tied to the LEFTBUTTON and RIGHTBUTTON parameters (Default = 1)

### LEFTBUTTON
joystick button to be used for a left selection (Default = 4 / LB Button on xbox 360 joypad)

### RIGHTBUTTON
joystick button to be used for a right selection (Default = 5 / RB Button on xbox 360 joypad)

### LAUNCHBUTTON
joystick button to be used to confirm the selection and launch the game (Default = 0 / A Button on xbox 360 joypad)

### LAUNCHBUTTON2
Alternate joystick button to be used to confirm the selection and launch the game (Default = 1 / B Button on xbox 360 joypad)

### QUITBUTTON
joystick button to be used to quit the launcher (Default = 6 / back Button on xbox 360 joypad)

### LEFTRIGHTAXIS
Used to specify which axis to use to make left an right selections (Default = 0 / X-Axis on xbox 360 joypad)

### LEFTRIGHTAXISDEADZONE
used to specify the deadzone value, a joypad axis might never be exactly 0 in resting position so you can provide a value here before it registers the axis values (both negative and positive) (Default = 0,5)

### JOYPOVLEFTMIN
Minimum value of the POV to be registered as a left direction, Used in conjunction with JOYPOVLEFTMAX (Default = 260)

### JOYPOVLEFTMAX
Maximum value of the POV to be registered as a left direction, Used in conjunction with JOYPOVLEFTMIN (Default = 280)

### JOYPOVRIGHTMIN
Minimum value of the POV to be registered as a right direction, Used in conjunction with JOYPOVRIGHTMAX (Default = 80)

### JOYPOVRIGHTMAX
Maximum value of the POV to be registered as a left direction, Used in conjunction with JOYPOVLEFTMIN (Default = 100)


## ADVANCED INI SETTINGS
If you make a copy of the executable and rename it and then start it again a seperate ini file will be created (same name as binary) using  same 
default settings above, you can then use the following section to change the behaviour of this app to be used with other games than the 
default Zaccaria pinball settings or even outside pinballx. For example if you have other apps that can use parameter sets you like to select. You can configure
up to 12 buttons each with it's own parameters. Each Button section consits of 3 values to be specifed..

### TEXT
Specifies the text to be shown on the button, this will be word and letter wrapped as well as clipped if the text is too long

### ENABLED
Specifies if the button is enabled / visible to be selected

### PARAM
Specifies the parameter that will be used to launch your application when this button is selected.

## CREDITS
RotateFlipBitmap function - GolezTrol

https://www.nldelphi.com/showthread.php?42769-Bitmap-90-graden-roteren&p=358213&viewfull=1#post358213

SmoothScaleBitmap function - Dalija Prasnikar

https://stackoverflow.com/questions/33608134/fast-way-to-resize-an-image-mixing-fmx-and-vcl-code

ForceForegroundWindow function - unknown

https://www.swissdelphicenter.ch/en/showcode.php?id=261

NLDJoystick created by Albert de Weerd (aka NGLN)

https://www.nldelphi.com/showthread.php?29812-NLDJoystick
http://svn.nldelphi.com/nldelphi/opensource/ngln/NLDJoystick/

## Donations
[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://paypal.me/joyrider3774)


