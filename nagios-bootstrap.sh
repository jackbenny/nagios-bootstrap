#!/bin/bash

################################################################################
#                                                                              #
#  Copyright (C) 2014 Jack-Benny Persson <jack-benny@cyberinfo.se>             #
#                                                                              #
#   This program is free software; you can redistribute it and/or modify       #
#   it under the terms of the GNU General Public License as published by       #
#   the Free Software Foundation; either version 2 of the License, or          #
#   (at your option) any later version.                                        #
#                                                                              #
#   This program is distributed in the hope that it will be useful,            #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#   GNU General Public License for more details.                               #
#                                                                              #
#   You should have received a copy of the GNU General Public License          #
#   along with this program; if not, write to the Free Software                #
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  #
#                                                                              #
################################################################################

# nagios-bootstrap

# Binaries
Which="/bin/which"
Binaries=(nmap sed awk printf ls grep egrep cut tr head)

# Variables
Version="0.1"
Author="Jack-Benny Persson <jack-benny@cyberinfo.se>"
Plugindir="dummy_checks/"


# Sanity check binaries and create variables for them
Count=0
for i in ${Binaries[@]}; do
	$Which $i &> /dev/null
	if [ $? -eq 0 ]; then
		declare $(echo ${Binaries[$Count]^}=`${Which} $i`)
		((Count++))
	else
		echo "It seems you don't have ${Binaries[$Count]} installed"
		exit 1
	fi
done


# Define functions
print_usage()
{
	$Printf "\n`basename $0`\nVersion $Version\n"
	$Printf "$Author\n\n"
	$Printf "Usage: `basename $0` -H <host> -o <output-file> -h (help)\n\n"
}

print_help()
{
	print_usage
	$Printf "-h This help screen\n"
	$Printf "-H Host to scan and bootstrap for Nagios\n"
	$Printf "-o Output file to save the configuration file in\n\n"
}

# Parse options and arguments
while getopts H:ho: Opts; do
	case "$Opts" in
	h) print_help
	   exit 0
	   ;;
	o) Outfile="$OPTARG"
	   exec 1> $Outfile
	   ;;
	H) Host="$OPTARG"
	   ;;
	*) print_usage >&2
	   exit 1
	   ;;
	esac
done

# Check if have at least two args (one option + one argument)
if [ $# -lt 2 ]; then
	print_usage >&2
	exit 1
fi

### Main ###

# Scan the host and save all the output in a variable
Output=`$Nmap $Host 2> /dev/null`

# Check if the host is up before contiuing
echo $Output | $Grep "Host is up" &> /dev/null
if [ $? -ne 0 ]; then
	echo "Host appears to be down or host not found" >&2
	exit 1
fi

# Set all the host and service variables
IP=`echo "$Output" | $Sed -n '3p' | $Tr -d '()' | $Awk '{ print $6 }'`
Hostname=`echo "$Output" | $Sed -n '3p' | $Awk '{ print $5 }'`
Alias=`echo $Hostname | $Awk -F"." '{ print $1 }'`
Services=(`$Nmap $Host | $Sed -n '9,$p' | $Head -n -2 \
	| $Awk '{ print $3 }'`)


# Loop through the services that were found open and check if we have
# a matching Nagios check for it
Index=0
for i in ${Services[@]}; do
	TempServ=`$Ls ${Plugindir}/ | $Egrep -x check_$i`
	if [ $? -eq 0 ]; then
		CheckCommand[$Index]=$TempServ
		((Index++))
	fi
done

# Print the host definition
$Printf "define host {\n"
$Printf "\thost_name\t${Hostname}\n"
$Printf "\talias\t\t${Alias}\n"
$Printf "\taddress\t\t${IP}\n"
$Printf "\tuse\t\tgeneric-host\n"
$Printf "\t}\n\n"

# Loop through the services and print a service definition for each one
CheckIndex=0
for i in ${CheckCommand[@]}; do
	Desc=`echo ${CheckCommand[$CheckIndex]} | $Cut -c7-50`
	$Printf "define service {\n"
	$Printf "\tuse\t\t\tgeneric-service\n"
	$Printf "\thost_name\t\t${Hostname}\n"
	$Printf "\tservice_description\t${Desc}\n"
	$Printf "\tcheck_command\t\t${CheckCommand[$CheckIndex]}\n"
	$Printf "}\n\n"
	((CheckIndex++))
done

exit 0
