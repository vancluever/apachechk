#!/usr/bin/env bash

# apachechk: A proof-of-concept script to check apache
#
# This script will:
#     -- Check for running apache processes against a defined threshold
#     -- Attempt a restart if a critical situation is encountered (ie: not running, or over a critical threshold)
#     -- Messages are logged to both local log file and syslog (optional), and console if TTY is present

# CONFIGURATION

# Name of process to search for
APACHE_CMDNAME="apache2"

# Command line to restart apache (expects SysV init script)
APACHE_RESTART="/etc/init.d/apache2"

# Restart on <= 1 processes? (Assumes that means zero children are running)
# (0=no 1=yes) Critical is logged regardless of if restart is desired.
RESTART_NO_CHILDREN=0

# Thresholds for warning or critical process levels
THRESH_WARN=20
THRESH_CRIT=100

# Debug wait interval - for running script in foreground and not in cron
# Dictates frequency of check cycle
DEBUG_CYCLE=30

# Log to local file (0=no 1=yes)
LOG_LOCAL=1
# Local log file
LOG_LOCAL_FILE="/tmp/apachechk.log"
# Log file max size (KB, 0=do not rotate)
LOG_ROTATE_KB=10

# Use syslog (0=no 1=yes)
LOG_SYSLOG=0
# Syslog server to send messages to (blank to use local server)
LOG_SYSLOG_REMOTEHOST=""
# Syslog facility to use
LOG_SYSLOG_FACILITY="local0"
# Syslog hostname for remote logging - recommend leaving at system hostname
LOG_SYSLOG_HOSTNAME=`hostname`
# Syslog port for remote logging
LOG_SYSLOG_PORT=514

check() {
	# main check workhorse
	
	APACHE_RUNNUM=`ps -C $APACHE_CMDNAME --no-headers | wc -l`
	if [ $APACHE_RUNNUM -lt 2 ] ; then
		msg "[CRITICAL] Web server not running! (Re)start required" err
		if [ $RESTART_NO_CHILDREN -eq 1 ] ;then
			restart_start start
		fi
	elif [ $APACHE_RUNNUM -lt $THRESH_WARN ] ; then
		msg "[LOW] Web Server OK!" info
	elif [ $APACHE_RUNNUM -lt $THRESH_CRIT ] ; then
		msg "[HIGH] Web Server Working hard!" warning
	else
		msg "[CRITICAL] Web Server under heavy load, restart required" err
		restart_start restart
	fi
}

restart_start () {
	# restarts or starts apache

	# restart or start
	START=$1
	msg "[Server] Apache operation ($START) requested, running..." notice
	$APACHE_RESTART $START
	if [ $? != 0 ] ; then
		msg "[Server] Apache operation ($START) failed, check apache logs for further details" alert
	else
		msg "[Server] Apache operation ($START) succeeded" notice
	fi
}

msg() {
	# Log message management
	
	MESSAGE=$1
	PRIORITY=$2
	DATE=`date`

	# log to console
	echo "$DATE $MESSAGE"

	if [ $LOG_LOCAL = 1 ] ; then
		msg_logfile "$DATE $MESSAGE"
	fi
	if [ $LOG_SYSLOG = 1 ] ; then
		# syslog does not need date appended
		msg_syslog "$MESSAGE" $PRIORITY
	fi
}

msg_logfile() {
	# log message to log file, rotating if necessary

	LOGFILE_MESSAGE=$1

	# rotation - using copy/trunc-style rotation, just to be safe
	if [ -f $LOG_LOCAL_FILE ] ; then
		# check for rotation
		if [[ $((`stat -c %s $LOG_LOCAL_FILE` / 1000)) -ge $LOG_ROTATE_KB && $LOG_ROTATE_KB -gt 0 ]] ; then
			FILESTAMP=`date +%Y%m%d-%H_%M_%S`
			cp $LOG_LOCAL_FILE "$LOG_LOCAL_FILE.$FILESTAMP"
		
			# write new message to log - truncating
			echo $LOGFILE_MESSAGE > $LOG_LOCAL_FILE
		else
			# append
			echo $LOGFILE_MESSAGE >> $LOG_LOCAL_FILE
		fi
	else
		# new file - truncate
		echo $LOGFILE_MESSAGE > $LOG_LOCAL_FILE
	fi
}

msg_syslog() {
	# send message to syslog using logger

	SYSLOG_MESSAGE=$1
	SYSLOG_PRIORITY=$2
	if [ -z "$LOG_SYSLOG_PORT" ] ; then
		LOG_SYSLOG_PORT=514
	fi

	if [ -z "$LOG_SYSLOG_REMOTEHOST" ] ; then
		logger -t apachechk -p "$LOG_SYSLOG_FACILITY.$SYSLOG_PRIORITY" $SYSLOG_MESSAGE
	else
		logger -t "$LOG_SYSLOG_HOSTNAME apachechk" -p "$LOG_SYSLOG_FACILITY.$SYSLOG_PRIORITY" -n $LOG_SYSLOG_REMOTEHOST -P $LOG_SYSLOG_PORT $SYSLOG_MESSAGE
	fi
}

# Main
case "$1" in
	--debug)
		# Debug mode
		while true
		do
			check
			sleep $DEBUG_CYCLE
		done		
		;;
	"")
		# Normal operation
		check
		exit 0
		;;
	*)
		# Error - usage
	        echo "Usage: $0 [--debug]" >&2
		exit 1
		;;
esac
