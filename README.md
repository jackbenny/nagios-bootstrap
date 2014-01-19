# nagios-bootstrap #
This is a Bash script meant to aid system administrators to quickly get a
Nagios instance up and running. The script scans through a specified host for
open services and matches those services to avaliable Nagios checks/plugins
found on the system. If the open service has a matching plugin it is added to
the config file. Once every open service has been found (using Nmap) and
matched to a plugin the script creates a config file with all the data. If the
-o option is omitted, the config file will be printed to stdout.

## Usage ##
To create a config file for the the host _host1.example.com_ and save the 
config in _host1.cfg_ issue the following
command `./nagios-bootstrap.sh -H host1.example.com -o host1.cfg`. If the -o
option is ommited the output will be printed to stdout instead.
