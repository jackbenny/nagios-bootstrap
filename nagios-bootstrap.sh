#!/bin/bash

# Binaries
Nmap="/usr/bin/nmap"
Sed="/bin/sed"
Awk="/usr/bin/awk"
Printf="/usr/bin/printf"
Ls="/bin/ls"
Grep="/bin/grep"
Cut="/usr/bin/cut"

# Variables
Version="0.1"
Plugindir="dummy_checks"

# Sanity check
for Bin in $Nmap $Sed $Awk $Printf; do
	if [ ! -x $Bin ]; then
		echo "Can't execute $Bin"
	fi
done

print_usage()
{
	$Printf "Usage: `basename $0` -H <host> -o <output> -h (help)\n"
}

print_help()
{
	$Printf "-h This help screen\n"
	$Printf "-H Host to scan and bootstrap for Nagios\n"
	$Printf "-o Output file to save the configuration file in\n"
}

# Parse options and arguments
while getopts H:ho: Opts; do
	case "$Opts" in
	h) print_help
	   exit 1
	   ;;
	o) Outfile="$OPTARG"
	   exec 1> $Outfile
	   ;;
	H) Host="$OPTARG"
	   ;;
	*) print_usage
	   exit 1
	   ;;
	esac
done

### Main ###

# Scan the host and save all the output in a variable
Output=`$Nmap $Host`

IP=`echo "$Output" | $Sed -n '3p' | tr -d '()' | awk '{ print $6 }'`
Hostname=`echo "$Output" | $Sed -n '3p' | awk '{ print $5 }'`
Alias=`echo $Hostname | $Awk -F"." '{ printf $1 }'`

Services=`nmap labrat.nixnet.jke | sed -n '7,$p' | head -n -2 \
	| awk '{ print $3 }'`

Index=0
for i in ${Services[@]}; do
	TempServ=`$Ls ${Plugindir}/ | $Grep $i`
	if [ $? -eq 0 ]; then
		CheckCommand[$Index]=$TempServ
		((Index++))
	fi
done

$Printf "define host {\n"
$Printf "\thost_name\t${Hostname}\n"
$Printf "\talias\t\t${Alias}\n"
$Printf "\taddress\t\t${IP}\n"
$Printf "\tuse\t\tgeneric-host\n"
$Printf "\t}\n\n"

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
