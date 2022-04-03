#!/bin/bash

# Version 0.3
# GPL3
# Contributors - smurphos & Koentje

# A script for the Cinnamon & Mate desktops to launch from your conky to set a blurred background image based on your current wallpaper.
# The background will update automatically with changes in wallpaper and changes in conky window geometry.

# The conky.config section of your conky must include :
#   - own_window = true,
#   - own_window_type = 'desktop',         (or dock)
#   - own_window_title = '<unique-name>',  (this should be an unique name for every conky config if you use more than one. Do not use spaces)
#   - own_window_transparent = true,
#   - own_window_argb_visual = false,

# To ensure the conky blurred background updates in a timely manner following a wallpaper change we also recommend setting a short update_interval in the conky config

# The text section of your conky should include:
#   - In the first line of the text section: 
#     ${image ~/.conky/conky_blurred_background/<unique-name>.png -n -p -1,-1} (<unique-name> is the same name you use for own_window_title above)
#   - Anywhere in the body of the conky text - note any errors messages produced by the script will display at this position in your conky.
#	  ${exec conky-blur-background.sh}

# conky-blur-background.sh can also be executed from your conky with optional arguments. These are

#   -blurradius= (Integer between 0 and 10)
#   -blursigma= (Integer between 0 and 40)
#   -brightness= (Integer between -100 and +100. The - or + sign must be included)
#   -contrast= (Integer between -100 and +100. The - or + sign must be included)
#   -curviness= (Integer between 0 and 40. Sets the roundness of the conky corners)

#   -help (This argument is only valid if the script is launched from a terminal)

# For more information see https://imagemagick.org/script/command-line-options.php#blur
# and https://imagemagick.org/script/command-line-options.php#brightness-contrast

# Example - ${exec conky-blur-background.sh -blurradius=0 -blursigma=8 -brightness=-15 -contrast=+0 -curviness=30}

# Requires packages wmctrl, imagemagick, x11-xserver-utils, x11-utils & dconf-cli

# As written this is for the Cinnamon desktop only and will automatically update on wallpaper changes.

# Save the script as ~/.local/bin/conky-blur-background.sh and make executable. Adjust your preferred conky config to meet the above requirements and then execute your conky.

#Functions

function clear_wallpaper_cache {
    DCONF_WALL=$(dconf read "$DCONF_KEY")
    rm -r ~/.cache/wallpaper
    dconf write "$DCONF_KEY" "0"
    dconf write "$DCONF_KEY" "$DCONF_WALL"
}

function write_wallpaper {
	# Create mask for curved corners
	if ! convert -size "$WIDTH"x"$HEIGHT" xc:white -draw "roundRectangle 0,0 $WIDTH,$HEIGHT $CURVINESS,$CURVINESS" /tmp/"$CONKY_WINDOW"_background_mask.png; then
		report_error "ERROR: Failed to create mask"
	fi
	# Apply mask, blur and contrast changes to crop
	if ! convert /tmp/"$CONKY_WINDOW"_background.png -mask /tmp/"$CONKY_WINDOW"_background_mask.png -blur "$BLUR" -brightness-contrast "$BRIGHTNESS" +mask ~/.conky/conky_blurred_background/"$CONKY_WINDOW".png; then
		report_error "ERROR: Failed to create masked image"
	fi
	# Write the wallpaper cache
	echo "${WALLPAPER["$1"]}" > ~/.conky/conky_blurred_background/"$CONKY_WINDOW"_wallpaper_cache
	rm -f ~/.conky/conky_blurred_background/"$CONKY_WINDOW"_Geometry_*
	touch ~/.conky/conky_blurred_background/"$CONKY_WINDOW"_Geometry_"$WIDTH"x"$HEIGHT""$TOP_LEFT"_Params_"$BLUR"_"$BRIGHTNESS"_"$CURVINESS"
	exit 0
}

function report_error {
	# Estimate columns available from conky geometry and default font size. If no geometry available default to 60 columns for wrapping of error messages.
	if [ "$WIDTH" ] ; then
		FONT_SIZE=$(grep -w 'font = ' "$CONKY_CONF" | xargs | cut -d'=' -f3 | sed s/,*$//g)
		# Assume characters are square (will underestimate columns needed for nearly all fonts)
		COLUMNS=$(( WIDTH / FONT_SIZE ))
	else
		COLUMNS=60
	fi
	echo -e "$1\n" | fold -s -w "$COLUMNS"
	exit 1
}

# Main script starts here

# Catch help argument
if [[ "$1" == -help ]] && tty -s; then
    echo -e "\n$(basename "$0") is intended to be executed from within a conky config.\n\nExample of command to use in your conky config:\n\nexec $0\n\nOptional arguments can be included to set the parameters of the conky background produced.\nIf an argument is not present a sensible default will be used.\n\nFor more information see https://imagemagick.org/script/command-line-options.php#blur\nand https://imagemagick.org/script/command-line-options.php#brightness-contrast\n\n-blurradius= (Integer between 0 and 10)\n-blursigma= (Integer between 0 and 40)\n-brightness= (Integer between -100 and +100. The - or + sign must be included)\n-contrast= (Integer between -100 and +100. The - or + sign must be included)\n-curviness= (Integer between 0 and 40. Sets the roundness of the conky corners)\n\nExample of a command line with arguments:\n\nexec $0 -blurradius=0 -blursigma=8 -brightness=-15 -contrast=+0 -curviness=30\n\nThe conky.config section of your conky must include :\n\n- own_window = true,\n- own_window_type = 'desktop',         (or dock)\n- own_window_title = '<unique-name>',  (this should be an unique name for every conky config if you use more than one. Do not use spaces)\n- own_window_transparent = true,\n- own_window_argb_visual = false,\n\nTo ensure the conky blurred background updates in a timely manner following a wallpaper change we also recommend setting a short update_interval in the conky config.\n\nThe text section of your conky must include (recommended on the first line) :\n\n\${image ~/.conky/conky_blurred_background/<unique-name>.png -n -p -1,-1} (<unique-name> is the same name you use for own_window_title above)\n\nThe text section of your conky must also include (in any position):\n\n\${exec $0}\n"
    exit 0
fi

# Make directory if it doesn't already exist for storage of persistent script files
mkdir -p ~/.conky/conky_blurred_background

# Check that dependencies are available
if ! type wmctrl > /dev/null; then
  report_error "ERROR: $(basename "$0") requires wmctrl to be installed."
fi
if ! type convert > /dev/null; then
  report_error "ERROR: $(basename "$0") requires imagemagick to be installed."
fi
if ! type xrandr > /dev/null; then
  report_error "ERROR: $(basename "$0") requires x11-xserver-utils to be installed."
fi
if ! type xwininfo > /dev/null; then
  report_error "ERROR: $(basename "$0") requires x11-utils to be installed."
fi
if ! type dconf > /dev/null; then
  report_error "ERROR: $(basename "$0") requires dconf-cli to be installed."
fi

# Get command line of parent conky
COMMAND_LINE="$(ps -p "$(ps -o ppid= -p "$PPID"|xargs)" -o args --no-headers)"
# If no conky in command line then error
if ! echo "$COMMAND_LINE" | awk '{print $1}' | grep -q "conky"; then
	report_error "ERROR: $(basename "$0") is intended to be executed from a conky config"
fi

# Can we find the CONKY_CONF and does it exist?
CONKY_CONF=$(echo "$COMMAND_LINE" | awk '{print $3}')
if [ ! -f "$CONKY_CONF" ]; then
	report_error "ERROR: File $CONKY_CONF does not exist"
fi

# Get conky window name, removing trailing comma if necessary
CONKY_WINDOW=$(grep -w 'own_window_title' "$CONKY_CONF" | xargs | cut -d' ' -f3 | sed s/,*$//g)

# If an empty string error
if [ ! "$CONKY_WINDOW" ]; then
	report_error "ERROR: Set a unique own_window_title in $(basename "$CONKY_CONF")"
fi

# Get conky window ID
CONKY_WINDOW_ID=$(wmctrl -l | grep -e "-1 $(hostname) $CONKY_WINDOW" | awk '{print $1}')
# If empty string exit - conky will rerun the script at the next interval update
if [ ! "$CONKY_WINDOW_ID" ]; then
 exit 1
fi

# Get conky window geometry (do this early so we have a WIDTH variable for any further errors)
XWININFO_OUTPUT=$(xwininfo -id "$CONKY_WINDOW_ID")
WIDTH=$(echo "$XWININFO_OUTPUT" | grep "Width:" | awk '{print $2}')
# Increment value by 1 to avoid a single pixel border on right/bottom of window
((WIDTH++))
HEIGHT=$(echo "$XWININFO_OUTPUT" | grep "Height:" | awk '{print $2}')
# Increment value by 1 to avoid a single pixel border on right/bottom of window
((HEIGHT++))
TOP_LEFT=$(echo "$XWININFO_OUTPUT" | grep "Corners:" | awk '{print $2}')

# Set wallpaper cache location for desktop environment.
# Currently Cinnamon only - MATE may be supported in future
if [ "$DESKTOP_SESSION" == "cinnamon" ]; then
	WALLPAPER_CACHE="$HOME/.cache/wallpaper/"
	SPANNED=0_6_
	DCONF_KEY=/org/cinnamon/desktop/background/picture-uri
elif [ "$DESKTOP_SESSION" == "mate" ]; then
	WALLPAPER_CACHE="$HOME/.cache/mate/background/"
	SPANNED=0_5_
	DCONF_KEY=/org/mate/desktop/background/picture-filename
else
	report_error "ERROR: Unsupported Desktop Environment. Currently only Cinnamon is supported."
fi

# Validate other conky config characteristics
# Does the conky conf include a command to display the image?
if ! grep -Eq "image $HOME/.conky/conky_blurred_background/$CONKY_WINDOW.png -n -p -1,-1|image ~/.conky/conky_blurred_background/$CONKY_WINDOW.png -n -p -1,-1" "$CONKY_CONF"; then
	report_error "ERROR: $(basename "$CONKY_CONF") does not include a command to display the blurred background. Add '\${image ~/.conky/conky_blurred_background/$CONKY_WINDOW.png -n -p -1,-1}' to $CONKY_CONF"
fi
OWN_WINDOW=$(grep -w 'own_window' "$CONKY_CONF" | xargs | cut -d' ' -f3 | sed s/,*$//g)
if [ "$OWN_WINDOW" != "true" ]; then
	report_error "ERROR: own_window in $(basename "$CONKY_CONF") must be set to true."
fi
OWN_WINDOW_TYPE=$(grep -w 'own_window_type' "$CONKY_CONF" | xargs | cut -d' ' -f3 | sed s/,*$//g)
if [ "$OWN_WINDOW_TYPE" != "desktop" ] && [ "$OWN_WINDOW_TYPE" != "dock" ]  ; then
	report_error "ERROR: own_window_type in $(basename "$CONKY_CONF") must be set to desktop or dock."
fi
OWN_WINDOW_TRANSPARENT=$(grep -w 'own_window_transparent' "$CONKY_CONF" | xargs | cut -d' ' -f3 | sed s/,*$//g)
if [ "$OWN_WINDOW_TRANSPARENT" != "true" ];  then
	report_error "ERROR: own_window_transparent in $(basename "$CONKY_CONF") must be set to true."
fi
ARGB_VISUAL=$(grep -w 'own_window_arb_visual' "$CONKY_CONF" | xargs | cut -d' ' -f3 | sed s/,*$//g)
if [ "$ARGB_VISUAL" == "true" ];  then
	report_error "ERROR: own_window_arb_visual in $(basename "$CONKY_CONF") must be set to false."
fi

# Arguments - if no arguments or arguments not correct format default values will be used.
for args in "$@"; do
	if [[ $args == -help ]]; then
		 report_error "ERROR: -help is not a valid argument when the script is executed from a conky config. Run $(basename "$0") -help in a terminal for all options."
	fi
	if [[ $args == -blurradius=* ]]; then
		BLUR_RADIUS=$(echo "$args" | cut -f2 -d"=")
		if ! [[ "$BLUR_RADIUS" =~ ^[0-9]+$ ]] || [ "$BLUR_RADIUS" -lt 0 ] || [ "$BLUR_RADIUS" -gt 10 ];  then
			report_error "ERROR: Invalid value for -blurradius=. This parameter accepts integers between 0 and 10. Run $(basename "$0") -help in a terminal for all options."
		fi
		continue
	fi
	if [[ $args == -blursigma=* ]]; then
		BLUR_SIGMA=$(echo "$args" | cut -f2 -d"=")
		if ! [[ "$BLUR_SIGMA" =~ ^[0-9]+$ ]] || [ "$BLUR_SIGMA" -lt 0 ] || [ "$BLUR_SIGMA" -gt 40 ];  then
			report_error "ERROR: Invalid value for -blursigma=. This parameter accepts integers between 0 and 40. Run $(basename "$0") -help in a terminal for all options."
		fi
		continue
	fi
	if [[ $args == -brightness=* ]]; then
		BRIGHTNESS=$(echo "$args" | cut -f2 -d"=")
		if [[ "$BRIGHTNESS" != +* ]] && [[ "$BRIGHTNESS" != -* ]];  then
			report_error "ERROR: Invalid value for -brightness=. This parameter accepts integers between -100 and +100. The - or + sign must be included. Run $(basename "$0") -help in a terminal for all options."
		fi
		if  ! [[ "${BRIGHTNESS:1}" =~ ^[0-9]+$ ]] || [ "${BRIGHTNESS:1}" -gt 100 ];  then
			report_error "ERROR: Invalid value for -brightness=. This parameter accepts integers between -100 and +100. The - or + sign must be included. Run $(basename "$0") -help in a terminal for all options."
		fi
		continue
	fi
	if [[ $args == -contrast=* ]]; then
		CONTRAST=$(echo "$args" | cut -f2 -d"=")
		if [[ "$CONTRAST" != +* ]] && [[ "$CONTRAST" != -* ]];  then
			report_error "ERROR: Invalid value for -contrast=. This parameter accepts integers between -100 and +100. The - or + sign must be included. Run $(basename "$0") -help in a terminal for all options."
		fi
		if  ! [[ "${CONTRAST:1}" =~ ^[0-9]+$ ]] || [ "${CONTRAST:1}" -gt 100 ]; then
			report_error "ERROR: Invalid value for -contrast=. This parameter accepts integers between -100 and +100. The - or + sign must be included. Run $(basename "$0") -help in a terminal for all options."
		fi
		continue
	fi
	if [[ $args == -curviness=* ]]; then
		CURVINESS=$(echo "$args" | cut -f2 -d"=")
		if ! [[ "$CURVINESS" =~ ^[0-9]+$ ]] || [ "$CURVINESS" -lt 0 ] || [ "$CURVINESS" -gt 40 ];  then
			report_error "ERROR: Invalid value for -curviness=. This parameter accepts integers between 0 and 40. Run $(basename "$0") -help in a terminal for all options."
		fi
		continue
	fi
report_error "ERROR: $args is not a recognised argument. Run $(basename "$0") -help in a terminal for all options."
done

# Apply defaults if arguments not set in command line.
if [ ! "$BLUR_RADIUS" ]; then
	BLUR_RADIUS=0
fi
if [ ! "$BLUR_SIGMA" ]; then
	BLUR_SIGMA=10
fi
BLUR="$BLUR_RADIUS"x"$BLUR_SIGMA"
if [ ! "$BRIGHTNESS" ]; then
	BRIGHTNESS=-10
fi
if [ ! "$CONTRAST" ]; then
	CONTRAST=0
fi
BRIGHTNESS="$BRIGHTNESS"x"$CONTRAST"
if [ ! "$CURVINESS" ]; then
	CURVINESS=20
fi

# Get xrandr output
XRANDR_OUTPUT=$(xrandr)

# If no existing cache of xrandr output or it has changed since last execution of script update cache copy and force refresh of wallpaper cache.
if [ ! -f ~/.conky/conky_blurred_background/xrandr_output ] || [ "$(cat ~/.conky/conky_blurred_background/xrandr_output)" != "$XRANDR_OUTPUT" ]; then
	echo "$XRANDR_OUTPUT" > ~/.conky/conky_blurred_background/xrandr_output
	clear_wallpaper_cache
fi

# Get current wallpaper(s)
WALLPAPER=("$WALLPAPER_CACHE"*)
# If cache has multiple wallpapers, but the first one is spanned, clear cache and reload, as the later ones are stale
if [ "${#WALLPAPER[@]}" -gt 1 ] && echo "${WALLPAPER[0]}" | grep -q "$SPANNED"; then
	clear_wallpaper_cache
	WALLPAPER=("$WALLPAPER_CACHE"*)
fi

#Check if we've already got a background based on this wallpaper cache and conky geometry and if so exit.
if [ -f ~/.conky/conky_blurred_background/"$CONKY_WINDOW"_wallpaper_cache ] && [ -f ~/.conky/conky_blurred_background/"$CONKY_WINDOW".png ] && [ -f ~/.conky/conky_blurred_background/"$CONKY_WINDOW"_Geometry_"$WIDTH"x"$HEIGHT""$TOP_LEFT"_Params_"$BLUR"_"$BRIGHTNESS"_"$CURVINESS" ]; then
    LAST_WALLPAPER=$(cat ~/.conky/conky_blurred_background/"$CONKY_WINDOW"_wallpaper_cache)
    counter=0
    for i in "${WALLPAPER[@]}"; do
        if [ "$LAST_WALLPAPER" == "${WALLPAPER[counter]}" ] ; then
            exit 0
        fi
        (( counter++ ))
    done
fi

# Get dimensions of screen and remove trailing comma from height
SCREEN_WIDTH=$(echo "$XRANDR_OUTPUT" | grep "Screen" | awk '{print $8}')
SCREEN_HEIGHT=$(echo "$XRANDR_OUTPUT" | grep "Screen" | awk '{print $10}'| xargs| cut -d' ' -f3 | sed s/,*$//g)
SCREEN_RES="$SCREEN_WIDTH"x"$SCREEN_HEIGHT"
# Get dimensions of wallpaper cache(s)
counter=0
for i in "${WALLPAPER[@]}"; do
	WALL_RES[counter]=$(identify -format %wx%h "$i")
	(( counter++ ))
done
# Scenario 1 - Single wallpaper cache file and dimensions match screen size.
if [ "${#WALLPAPER[@]}" -eq 1 ] && [ "${WALL_RES[0]}" == "$SCREEN_RES" ]; then
	# Crop the wallpaper to match conky window geometry
	if ! convert "${WALLPAPER[0]}" -crop "$WIDTH"x"$HEIGHT""$TOP_LEFT" /tmp/"$CONKY_WINDOW"_background.png; then
		report_error "ERROR: Initial wallpaper crop to conky geometry failed"
	fi
	write_wallpaper 0
fi
# Scenario 2 - Single wallpaper cache but image smaller than screen (implies background setting of Scaled or Spanned with an image that is too small)
if [ "${#WALLPAPER[@]}" -eq 1 ]; then
	# resize the image to the screen dimensions with empty space transparent.
	if ! convert "${WALLPAPER[0]}" -resize "$SCREEN_WIDTH"x"$SCREEN_HEIGHT" -background "rgba(255,255,255,0)" -gravity center -extent "$SCREEN_WIDTH"x"$SCREEN_HEIGHT" /tmp/"$CONKY_WINDOW"_resized_background.png; then
		report_error "ERROR: Initial wallpaper resize failed"
	fi
	# Crop the wallpaper to match conky window geometry
	if ! convert /tmp/"$CONKY_WINDOW"_resized_background.png -crop "$WIDTH"x"$HEIGHT""$TOP_LEFT" /tmp/"$CONKY_WINDOW"_background.png; then
		report_error "ERROR: Initial wallpaper crop to conky geometry failed"
	fi
	write_wallpaper 0
fi
# Now we have a situation where we have multiple monitors and multiple wall paper cache files.
# Get the screen size for each monitor in an array that matches the wallpaper array.
counter=0
for i in "${WALLPAPER[@]}"; do
	MONITOR_RES[counter]=$(echo "$XRANDR_OUTPUT" | grep "$(xrandr --listmonitors | grep "$counter:" | awk '{print $4}')" | awk '{print $3}')
	# The command above will return primary for one of the connected monitors - correct for this monitor,
	if [ "${MONITOR_RES[counter]}" == "primary" ];then
		MONITOR_RES[counter]=$(echo "$XRANDR_OUTPUT" | grep "$(xrandr --listmonitors | grep "$counter:" | awk '{print $4}')" | awk '{print $4}')
	fi
	(( counter++ ))
done
# Which monitor is the conky on?
TOP_LEFTX=$(echo "$TOP_LEFT" | cut -f2 -d"+")
TOP_LEFTY=$(echo "$TOP_LEFT" | cut -f3 -d"+")
counter=0
for i in "${MONITOR_RES[@]}"; do
	MON_WIDTH=$(echo "${MONITOR_RES[counter]}" | cut -f1 -d"x")
	MON_HEIGHT=$(echo "${MONITOR_RES[counter]}" | cut -f2 -d"x" | cut -f1 -d"+")
	MONX=$(echo "${MONITOR_RES[counter]}" | cut -f2 -d"+")
	MONY=$(echo "${MONITOR_RES[counter]}" | cut -f3 -d"+")
	# Is the conky fully on this monitor?
	if [ "$TOP_LEFTX" -ge "$MONX" ] && [ "$TOP_LEFTY" -ge "$MONY" ] && [ $(( TOP_LEFTX+WIDTH )) -lt $(( MONX+MON_WIDTH )) ] && [ $(( TOP_LEFTY+HEIGHT )) -lt $(( MONY+MON_HEIGHT )) ]  ; then
		# Adjust $TOP_LEFT to reflect relative position on this monitor
		TOP_LEFT_ADJ="+""$(( TOP_LEFTX - MONX ))""+""$(( TOP_LEFTY - MONY ))"
		# Is the wallpaper for this monitor the full size of the monitor?
		if [ "${WALL_RES[counter]}" == "$MON_WIDTH"x"$MON_HEIGHT" ]; then
			# Crop the wallpaper to match conky window geometry
			if ! convert "${WALLPAPER[counter]}" -crop "$WIDTH"x"$HEIGHT""$TOP_LEFT_ADJ" /tmp/"$CONKY_WINDOW"_background.png; then
				report_error "ERROR: Initial wallpaper crop to conky geometry failed"
			fi
			write_wallpaper $counter
		else
			if ! convert "${WALLPAPER[counter]}" -resize "$MON_WIDTH"x"$MON_HEIGHT" -background "rgba(255,255,255,0)" -gravity center -extent "$MON_WIDTH"x"$MON_HEIGHT" /tmp/"$CONKY_WINDOW"_resized_background.png; then
				report_error "ERROR: Initial wallpaper resize failed"
			fi
			# Crop the wallpaper to match conky window geometry
			if ! convert /tmp/"$CONKY_WINDOW"_resized_background.png -crop "$WIDTH"x"$HEIGHT""$TOP_LEFT_ADJ" /tmp/"$CONKY_WINDOW"_background.png; then
				report_error "ERROR: Initial wallpaper crop to conky geometry failed"
			fi
			write_wallpaper $counter
		fi
	fi
	(( counter++ ))
done
# If we get to this line the conky isn't being displayed fully on a single monitor and the monitors each have their own wallpaper cache - We can't handle that situation currently (probably ever!). 
report_error "ERROR: Could not identify a monitor for this conky. Make sure your conky displays fully on a single monitor or use the 'Spanned' option for your background picture aspect."
