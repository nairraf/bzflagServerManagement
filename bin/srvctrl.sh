#!/bin/bash

ROOT=~/
LOGDIR=$ROOT/logs
PIDDIR=$ROOT/pid
BINDIR=$ROOT/bin

# get the name of all created server scripts
# we invert the grep so that all scripts except srvctrl.sh are in the output
# we remove the .sh from the names to leave us with just simple names 
# example.sh becomes 'example'
# this way we can control things using this simeple name
#   like: srvctrl.sh start example
#
# all newly created scripts will automatically be picked up without needed to modify this file
SERVERS=`ls $ROOT/bin | grep -v srvctrl.sh | sed s/.sh//`

# we parse all the command line arguments and assign them to $ACTION and $TARGETS
# this way we can start/stop/restart just a single server, all servers, or just the specific servers we want
# example: srvctrl.sh start server1 server3 server6
#   $ACTION = start
#   $TARGETS = "server1 server3 server6"

ACTION="$1"
shift # move to the next parameter
TARGETS='' # this will contain all our targets
FORCE=0 # we set $FORCE to off by default # test with: (( $FORCE )) && echo "true" || echo "false"
while [ $# -gt 0 ]
do
    case "$1" in
    all)
        TARGETS=$SERVERS
        shift # move to the next parameter
        ;;
    *)
        # if we don't detect a keyword, we treat that as a user defined server - so add it to the targets list
        TARGETS="$TARGETS $1"
        shift # move to the next parameter
    esac
done

CURSRV=''

actionhelp() {
    printf "Usage: %s $ACTION <server> [<server> ... ]\n" "$0"
    printf "  Please provide a value for <server>\n"
    exit 1
}

getstatus() {
    if test -f "$PIDDIR/$CURSRV.gpid"
    then
        GPID=`cat $PIDDIR/$CURSRV.gpid`
        if [ ! -z "$GPID" ] # make sure that there is data in the gpid file
        then
            # exit normally if GPID is running, exit with error if not running
            # we must use GPID's as every time a map is changed the bzfs pid exits and restarts
            # the GPID remains the same as bzfs is a child to the shell script (which contains the loop)
            status=`pgrep -g $GPID`
            if [ ! -z "$status" ] # if status is not empty - meaning we found details for the running GPID
            then
                echo "  Server: $CURSRV is running (GPID: $GPID)"
                return 0
            else
                echo "  Server: $CURSRV is NOT running (GPID: $GPID)"
                return 1
            fi
        fi
    fi
    # there is no GPID file, and/or the file is empty
    echo "  Server: $CURSRV is NOT running (GPID: NULL)"
    return 1
}

startserver() {
    echo "  starting $CURSRV"
    ( $BINDIR/$CURSRV.sh >> $LOGDIR/$CURSRV.log 2>&1 ) &
    # retrieve the group pid
    # we must use the group pid to manage the bzfs server running inside our loop, as well as parent the script containing the loop
    echo `ps -p $! -h -o "%r"` > $PIDDIR/$CURSRV.gpid
}

start() {
    if [ -z "$TARGETS" ]
    then
        actionhelp
    fi

    for server in $TARGETS
    do
        CURSRV=$server
        echo "attempting to start $CURSRV"
        if ! getstatus
        then
            # server is not running, start it up
            startserver
            getstatus
            exit 0
        fi
    done
}

status() {
    if [ -z "$TARGETS" ]
    then
        actionhelp
    fi

    echo "server status:"

    for server in $TARGETS
    do
        CURSRV=$server
        getstatus
    done
}

stopserver() {
    # we use the group pid to kill the parent server script containing the loop, and all related/child process of it.
    # this will be the running bzfs instance that starts in the loop. the pid of this bzfs instance constantly changes
    # as every restart (example: /mapchange) is a new bzfs instance/new pid, but it retains the group pid, since it's 
    # still a child of the parent script containing the loop
    if test -f "$PIDDIR/$CURSRV.gpid"
    then
        GPID=`cat $PIDDIR/$CURSRV.gpid`
        if getstatus
        then
            echo "  Server: $CURSRV (GPID: $GPID) stopping"
            pkill -g $GPID >/dev/null
            sleep 1
            getstatus
        fi
        rm -f $PIDDIR/$CURSRV.gpid
    else
        echo "  Server: $CURSRV not running"
    fi
}

stop() {
    if [ -z "$TARGETS" ]
    then
        actionhelp
    fi

    for server in $TARGETS
    do
        CURSRV=$server
        stopserver
    done
}


restart() {
    if [ -z "$TARGETS" ]
    then
        actionhelp
    fi

    stop
    start
}


case $ACTION in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    *)
        echo ""
        printf "Usage: %s {start|stop|restart|status} {all | <server> [<server> ... ] }\n" "$0"
        echo ""
        echo "keyword 'all' or a list of one or more servers must be supplied"
        echo ""
        echo "keywords:"
        echo "  all                        - eitherdid yo all or a list of servers must be supplied"
        echo ""
        echo "  examples:"
        echo "    $0 start all             - starts all servers up"
        echo "    $0 stop all              - stops all servers"
        echo "    $0 start server1         - start just server1"
        echo "    $0 restart srv1 srv4     - restart just srv1 and srv4"
        echo "    $0 status srv2 srv5      - tests to see if srv2 and srv5 are running"
        echo ""
        exit 1
esac

exit $?