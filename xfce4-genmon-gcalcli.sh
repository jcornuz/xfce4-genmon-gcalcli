#!/bin/bash

#########################################################################
#
# You can minimally customize the script with the following options
# Note that you need a functionning gcalcli for this to output anything
# https://github.com/insanum/gcalcli
#
########################################################################

# Which program to open on click? Evolution, gnome-calendar, Thunderbird...
OnClick=/usr/bin/gnome-calendar

# How many months do you want to show?
Month=2

# How many extra days (besides today) of appointments do you want to show?
# if you chose Month=1 you probably need ExtraDays=0 here, otherwise
# you will only get the dates / times of your appointments but not the titles
# (this is due to gcalcli formatting)
ExtraDays=5

# How often do you want to update the calendar (in minutes)?
UpdateMins=60

# Color of current date
TodayForegroundColor="#4B4B3B"
TodayBackgroundColor="#FAFBFC"


#
# You shouldn't need to change anything beyond this point
#


# Temporary file where we store the calendar between updates
CalFile=/tmp/genmon-cal.txt
Refresh=FALSE

# if tempfile doesn't exist, create it and trigger refresh
if [[ ! -e $CalFile ]]; then
    touch $CalFile
    Refresh=TRUE
fi

# if tempfile is older than the update time, trigger refresh
if [ `stat --format=%Y $CalFile` -le $(( `date +%s` - ( $UpdateMins * 60 ))) ]; then
    Refresh=TRUE
fi

# if the tempfile is less than 10 bytes, trigger refresh
if [ $(stat -c%s $CalFile) -lt 10 ];then
    Refresh=TRUE
fi

# if required, refresh calendar and store into calendar file
if [ "$Refresh" == "TRUE" ]; then

    # get the gcalcli output
    endDate=$(date -d "+$ExtraDays days" +%D)"T23:59"
    Agenda=$(gcalcli --nocolor agenda $(date +%D)T00:00 $endDate)

    # Remove unused spaces between time and event's name
    Agenda=$(sed 's/\([a-p]m\)           /\1/g' <<< $Agenda)

    # remove space for all day events
    Agenda=$(sed 's/\([0-9].\)         /\1/g' <<< $Agenda)

    # if we show only one day (today) no need to display the date
    if [ "$ExtraDays" -eq 0 ];then
        Agenda=$(sed 's/[A-Z][a-z]. [A-Z][a-z]. [0-9].  //g' <<< $Agenda)
        Agenda=$(sed 's/            //g' <<< $Agenda)
    fi

    echo -e "$Agenda" > $CalFile
fi

#
# Show the Generic Monitor
#
echo "<txt>"$(date +'%A %d %B, %H:%M')"</txt>"
echo "<txtclick>$OnClick</txtclick>"
echo "<tool><span font_family='monospace'>"

# show the calendar (with custom color for today's date)
Today=$(date +%d)
echo -ne "$(cal -n $Month)" | sed "s/$Today/<span bgcolor=\"$TodayBackgroundColor\" fgcolor=\"$TodayForegroundColor\">$Today<\/span>/"

# show the agenda (cut depending on how many months we show
if [ "$Month" -eq 1 ];then
    echo -ne "$(cut -c 1-20 $CalFile)\n"
elif [ "$Month" -eq 2 ];then
    echo -ne "\n$(cut -c 1-42 $CalFile)\n"
else
    echo -ne "\n$(cut -c 1-64 $CalFile)\n"
fi

echo "</span></tool>"
