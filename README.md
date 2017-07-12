# systemparse
Perl script to parse system information into XML, JSON, or YAML format.

## Notes
This is my first attempt at Perl.  The idea is to utilize Perl to summarize some system information to pass on to a PHP web page.  
The code is functional, but currently placed to the side until I am ready for developing LAN tools for home networking.

## Usage

Usage: ./SystemParse.pl
        GNU             POSIX           Description
        --show          -s              Display on screen formatting.
        --csv           -c              Send output as comma separated values.
        --json          -j              Send output in JSON format.
        --xml           -x              Send output in XML format.
        --yaml          -y              Send output in YAML format.
        --help          -h              Displays this message.