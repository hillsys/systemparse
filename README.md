# systemparse
Perl script to parse system information into XML, JSON, or YAML format.

## Notes
This is my first attempt at Perl.  The idea is to utilize Perl to summarize some system information to pass on to a PHP web page.  
The code is functional, but currently placed to the side until I am ready for developing LAN tools for home networking.

## Usage

Usage: ./SystemParse.pl

GNU | POSIX | Description
--- | --- | ---
--show | -s | Display on screen formatting.
--csv | -c | Send output as comma separated values.
--json | -j | Send output in JSON format.
--xml | -x | Send output in XML format.
--yaml | -y | Send output in YAML format.
--help | -h | Displays this message.

## Output Example
This information is from the Debian 8 virtual machine I am utilizing as a router for DSL service.  This was utilizing `./SystemParse.pl -s`

Interface | MTU | MAC | IPv4 | Gateway
--- | --- | --- | --- | --- |
lo | 65536 | 00:00:00:00:00:00 | 127.0.0.1/8
eth0 | 1500 | 00:15:5d:0b:13:11
eth1 | 1500 | 00:15:5d:0b:13:12 | 172.31.0.1/24
eth2 | 1500 | 00:15:5d:0b:13:18 
eth3 | 1500 | 00:15:5d:0b:13:19
eth4 | 1500 | 00:15:5d:0b:13:1a
bridge01 | 1500 | 00:15:5d:0b:13:11 | 172.31.1.1/24
ppp0 | 1492

NameServers:  199.85.126.20  199.85.127.20

FileSystem | Size | Used | Available | PercentageUsed | Mount
--- | --- | --- | --- | --- | --- | 
/dev/sda3 | 2.9G | 1.1G | 1.7G | 39% | /
/dev/sda2 | 43M | 21M | 19M | 52% | /boot
/dev/sda1 | 37M | 236K | 37M | 1% | /boot/efi