#!/bin/bash
#
# mostly taken from https://forums.bzflag.org/viewtopic.php?f=79&t=9903 (optic delusion's post)
# with a few minor tweaks by me:
# 			the sed templeting engine idea to easily replace/control the same text across multiple server configs
#			the variable templates also allow moving things around easily as you just need to change the variables in here
#			moving the mapchange loadplugin call to the common configuration file
#
# Mapchange script
#
# FILE - sets the name of the mapchange configuration file and list of configurations
#        if FILE=mapchange then you get 'mapchange.out' as the output file of the plugin
#        with the selected configuration and 'mapchange.conf' is the list of configurations
#        to choose from.

# Configuration
#
ROOT=~/
CONFDIR=$ROOT/config
SRVCONFDIR=$CONFDIR/example
OUTFILE=$SRVCONFDIR/mapchange.out          			# base of configuration filename and output file
SLEEPTIME=2.5                                   	# Time in seconds to sleep between restarts
BZFS=$ROOT/v2.4.22/bin/bzfs		    				# bzflag server binary
TMPCONF=$SRVCONFDIR/tmp
SERVERTITLE="Example Server :: ActiveMap -"	# don't put forward slashes (/) in here!
SERVERPORT="5160"
DNSNAME="my.server.dns.name"
PUBLICKEY="PASTEyourSECRETkeyHERE"					# your list server key

# Build the output file and configuration file parameters for the mapchange plugin

# Loop forever - display name of the selected configuration
while cat $OUTFILE; do
	# replace our template variables with our desired text
	cat $SRVCONFDIR/common.conf $(cat $OUTFILE) >$TMPCONF
	# since the paths contain forward slashes we can't use the normal sed delimeter (s/.../.../g)
	# we change that to a pipe '|' so that we don't have to escape everything to death
	sed -i "s|__ROOT__|$ROOT|g" $TMPCONF
	sed -i "s|__CONFDIR__|$CONFDIR|g" $TMPCONF
	sed -i "s|__SRVCONFDIR__|$SRVCONFDIR|g" $TMPCONF
	sed -i "s|__SERVERPORT__|$SERVERPORT|g" $TMPCONF
	sed -i "s|__DNSNAME__|$DNSNAME|g" $TMPCONF
	# don't put forward slashes in SERVERTITLE!! if you do then change the delimeter like above
	sed -i "s/__SERVERTITLE__/$SERVERTITLE/g" $TMPCONF
	sed -i "s/__PUBLICKEY__/$PUBLICKEY/g" $TMPCONF
	# cleanup any double slashes - like '//', replace with a single slash '/'
	sed -i "s|//|/|g" $TMPCONF
	
	# start up the server with our newly assembled config file
	$BZFS -conf $TMPCONF
	# Wait some time between restarts
	sleep $SLEEPTIME
done