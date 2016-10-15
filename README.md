# i3metar

i3status wrapper to show current aviation weather in the i3bar. 

## usage

* install perl modules using cpan or your distro's package manager
* modify the `stationString` parameter in the `URL` constant to match your nearest airport's ICAO code
* in your .i3status.conf's general section, make sure to set `output_format = i3bar`
* invoke in your i3 config:
`    bar {
        status_command i3status | perl /home/luc/.config/i3/i3metar.pl
    }`
