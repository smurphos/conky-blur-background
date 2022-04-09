# Conky Blur Background

A bash script intended to be run from a conky config to create a blurred conky background image based on the underlying desktop wallpaper.

## Compatibility

The script is currently limited to the following desktop environments.

* Cinnamon (developed and tested on Cinnamon 5.2.7 - Linux Mint 20.3)
* MATE (partially tested on MATE 1.26 - Linux Mint 20.3)

It is intended to add support for additional Desktop Environments in future.

## Contributors

* [smurphos](https://github.com/smurphos)
* [Koentje](https://forums.linuxmint.com/memberlist.php?mode=viewprofile&u=317124)

## Screenshots

![Screen1](https://github.com/smurphos/conky-blur-background/blob/main/screenshots/2022-03-25_20-07.png)
![Screen2](https://github.com/smurphos/conky-blur-background/blob/main/screenshots/2022-03-25_20-08.png)
![Screen3](https://github.com/smurphos/conky-blur-background/blob/main/screenshots/2022-03-25_20-09.png)

## How to use

The script is shipped with a basic conky config for demonstration purposes.
It can also be used with any conky config that has the following characteristics.

The conky.config section must include :

* `own_window = true,`
* `own_window_type = 'desktop',` or `own_window_type = 'dock',` 
* `own_window_title = '<unique-name>',` this should be an unique name for every conky config if you use more than one. Do not use spaces.
* `own_window_class = 'Conkyblurred',`
* `own_window_transparent = true,`
* `own_window_argb_visual = false,`

To ensure the conky blurred background updates in a timely manner following a wallpaper change a short `update_interval` is also recommended

The text section of the conky must include:

In the first line :

`${image ~/.conky/conky_blurred_background/<unique-name>.png -n -p -1,-1}` (`<unique-name>` is the same name you use for `own_window_title` above)

Anywhere in the body of the conky text:

`${exec conky-blur-background.sh}`

`conky-blur-background.sh` can also be executed from your conky with optional arguments. These are

* `-blurradius=` (Integer between 0 and 10)
* `-blursigma=` (Integer between 0 and 40)
* `-brightness=` (Integer between -100 and +100. The - or + sign must be included)
* `-contrast=` (Integer between -100 and +100. The - or + sign must be included)
* `-curviness=` (Integer between 0 and 40. Sets the roundness of the conky background corners)

* `-help` (This argument is only valid if the script is executed from a terminal)

For more information about the image characteristic arguments see see https://imagemagick.org/script/command-line-options.php#blur
and https://imagemagick.org/script/command-line-options.php#brightness-contrast

Example of a command within the conky text using arguments:

`${exec conky-blur-background.sh -blurradius=0 -blursigma=8 -brightness=-15 -contrast=+0 -curviness=30}`

## Dependencies

The script requires the packages conky-all, wmctrl, imagemagick, x11-xserver-utils, x11-utils & dconf-cli to be installed.

## Installation via the terminal.

Create  directories for install if they don't already exist.
* `mkdir -p ~/.local/bin`

If ~/.local/bin/ didn't exist prior to this installation a log off and back on will be required to ensure the system adds this directory to your `$PATH` before you use the script from a conky config.


Download the current release
* `wget https://github.com/smurphos/conky-blur-background/raw/main/releases/current/conky-blur-background.zip`

Extract files from the zip
* `unzip -o conky-blur-background.zip`

Copy the script to ~/.local/bin
* `cp -r ./conky-blur-background/script/conky-blur-background.sh ~/.local/bin/`

If you want to test with the sample conky config that is included:

Create  directories for install if they don't already exist.

* `mkdir -p ~/.conky`
* `mkdir -p ~/.config/autostart`

Copy the conky files to ~/.conky
* `cp -r ./conky-blur-background/conky-blur-sample/ ~/.conky/`

Copy the desktop file to ~/.config/autostart
* `cp -r ./conky-blur-background/autostart/conky-blur-sample.desktop ~/.config/autostart/`

Log off and back in

## Reporting issues

If you need to raise a issue reporting a problem with the script please attach the following information in your bug report.

1) A screenshot!
2) Output of terminal command `cat ~/.xsession-errors` run during the session the bug occurred.
3) Output of terminal command `ls -a ~/.conky/conky_blurred_background` run during the session the bug occurred.
4) If using your own conky config a copy of that config.
