apachechk
=========

This is a proof-of-concept script to check apache.

This script will:

 * Check for running apache processes against a defined threshold
 * Attempt a restart if a critical situation is encountered
 (ie: not running, or over a critical threshold)
 * Messages are logged to both local log file and syslog (optional),
 and console if TTY is present

**THIS IS FOR DEMONSTRATION PURPOSES ONLY - RUN AT YOUR OWN RISK**

Usage
-----

### Single Run

Running the script without any options (`./apachechk.sh`) will perform a single run. 
This is useful for running the script out of cron or some other scheduler.

Make sure you redirect output to /dev/null (`./apachechk.sh > /dev/null`) to prevent
cron mail spam.

### Debug/Foreground Run

Running the script with the `--debug` flag (`./apachechk.sh --debug`) will run
the script in a loop, that can be configured from within the script (defaults to 
30 seconds, see below).

Configuration
-------------

There are several variables within the script that you can configure:

### Processes and Restart Paths

    APACHE_CMDNAME="apache2"
    APACHE_RESTART="/etc/init.d/apache2"

You can configure the process to search for, and the restart init script.

### Thresholds and Restart Behaviour

    RESTART_NO_CHILDREN=0
    THRESH_WARN=20
    THRESH_CRIT=100

Restart on apache not running is configurable (possibly useful if it crashes).
Only one restart attempt is made per run.

You can also reconfigure thresholds for warning and critical level messages.

### Wait Cycle

    DEBUG_CYCLE=30

This is the sleep time (in seconds) for the debug mode.

### Logging

    LOG_LOCAL=1
    LOG_LOCAL_FILE="/tmp/apachechk.log"
    LOG_ROTATE_KB=10

Local file logging is auto-rotating if `LOG_ROTATE_KB` is a value > 0.

    LOG_SYSLOG=0
    LOG_SYSLOG_REMOTEHOST=""
    LOG_SYSLOG_FACILITY="local0"
    LOG_SYSLOG_HOSTNAME=`hostname`
    LOG_SYSLOG_PORT=514

Syslog logging is done with the `logger` command. Commands are sent
to localhost using local (non-network) logging functionality if 
`LOG_SYSLOG_REMOTEHOST` is a blank value.

Questions? Comments?
--------------------

If you found this script at all useful, feel free to email me at
inbox@vancluevertech.com.

Thanks and enjoy!

--Chris

