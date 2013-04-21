#!/bin/bash
#
# ------------------------------------------------------
# Bamboo Startup Script for Unix
# ------------------------------------------------------

unset GREP_OPTIONS

#
# Check correct command line usage
#
usage() {
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
}

getFromWrapperConfig() {
    grep ^$1= $BAMBOO_INSTALL/conf/wrapper.conf | sed -e 's@=\.\./@=@' -e s/^[^=]*=// | paste -s -d" " -
}


[ $# -gt 0 ] || usage


# Run as user "vagrant"
#
$RUN_AS_USER=vagrant

#
# Get the action & configs
#
ACTION=$1

#
# Ensure the BAMBOO_INSTALL var for this script points to the
# home directory where Bamboo is is installed on your system.
#

STARTUP_SCRIPT=$(readlink -f $0 2>/dev/null || readlink $0 2>/dev/null || echo $0)
BAMBOO_INSTALL=$(dirname $STARTUP_SCRIPT)
BAMBOO_LOG_FILE=${BAMBOO_LOG_FILE:-$BAMBOO_INSTALL/logs/bamboo.log}

DEFAULTS_FILE=/etc/default/bamboo
[ -f $DEFAULTS_FILE ] && . $DEFAULTS_FILE

if [ "$BAMBOO_SUPPRESS_STDOUT_LOGGING" = "true" ] ; then
    BAMBOO_LOG_FILE=/dev/null
fi

export JAVA_HOME
export BAMBOO_INSTALL

#
# Find a PID for the pid file
#
BAMBOO_PID=${BAMBOO_PID:-$BAMBOO_INSTALL/bamboo.pid}

#
# Are we running on Windows? Could be, with Cygwin/NT.
#
case "`uname`" in
    CYGWIN*) PATH_SEPARATOR=";";;
    *) PATH_SEPARATOR=":";;
esac

curDir=$(pwd)
CLASSPATH=$(cd $BAMBOO_INSTALL && eval echo $(getFromWrapperConfig wrapper.java.classpath.*) | sed s/" "/$PATH_SEPARATOR/g)${PATH_SEPARATOR}${CLASSPATH}
cd $curDir

PATH="$JAVA_HOME/bin:$PATH"
#
# This is how the Bamboo server will be started
#
RUN_CMD="$(getFromWrapperConfig wrapper.java.command) $(getFromWrapperConfig wrapper.java.additional.*) -classpath $CLASSPATH $BAMBOO_OPTIONS $(getFromWrapperConfig wrapper.app.parameter.*)"

if [ -n "$RUN_AS_USER" ] ; then
    RUNNER="su - $RUN_AS_USER -c"
else
    RUNNER="sh -c"
fi

if [ -f $BAMBOO_PID ] ; then
    PID=`cat $BAMBOO_PID 2>/dev/null`
    if [ -z "$PID" ] || ! ps "$PID" >/dev/null ; then
        echo "Bamboo with pid=${PID} is not running - removing old pidfile"
        unset PID
        rm -f $BAMBOO_PID
    fi
fi

#
# Do the action
#
case "$ACTION" in
  start)
        echo "Starting Bamboo: "

        if [ -n "$PID" ] ; then
            echo "Already Running!!"
            exit 1
        fi

        echo "STARTED Bamboo `date`"

        $RUNNER "nohup sh -c \"cd $BAMBOO_INSTALL && exec $RUN_CMD 2>&1\" >$BAMBOO_LOG_FILE & umask 022 ; echo \$! > $BAMBOO_PID"
        echo "Bamboo running, pid=$(cat $BAMBOO_PID)"
        ;;

  console)
        echo "Starting Bamboo: "

        if [ -n "$PID" ] ; then
            echo "Already Running!!"
            exit 1
        fi

        echo "STARTED Bamboo `date`"

        $RUNNER "cd $BAMBOO_INSTALL && $RUN_CMD"
        ;;
  
  stop)
        if [ -n "$PID" ] ; then
            echo "Shutting down Bamboo, pid=$PID"
            kill $PID 2>/dev/null
            sleep 2
            kill -9 $PID 2>/dev/null
            rm -f $BAMBOO_PID
            echo "STOPPED `date`"
        else
            echo "Bamboo is currently not running."
        fi
        ;;

  restart)
        $0 stop $*
        sleep 5
        $0 start $*
        ;;

  status)
        if [ -n "$PID" ] ; then
            echo "Bamboo running, pid=$PID"
            exit 0
        else
            echo "Bamboo is currently not running."
            exit 1
        fi
        ;;

*)
        usage
        ;;
esac

exit 0
