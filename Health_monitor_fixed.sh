#!/bin/bash
# ===================================================
# BAD SERVER HEALTH MONITOR SCRIPT
# (Written intentionally terrible for students)
#For educational chaos only. Written to annoy anyone reading it.
# ===================================================

# Global variables ?
#ANOTHER_TEMP is unecessary. let count=0 is pointless and isn't used anywhere else.
LOGFILE="/tmp/server_health.log"
TEMPFILE="/tmp/tempfile.tmp"

#starts log files empty.so no repeats.
: > "$LOGFILE"
: > "$TEMPFILE"

# function that writes headers, or footers? or something?
#nothing wrong with header
function headerWriter() {
    echo "--------------------------------------" >> "$LOGFILE"
    echo "Server Health Report - $(date)" >> "$LOGFILE"
    echo "--------------------------------------" >> "$LOGFILE"
}

# Function to check CPU vibes
#useless sed line. $TEMPFILE needs to be trunicated.
function checkCPU() {
    echo "Checking CPU..." >> "$LOGFILE"
	: > "$TEMPFILE"
    top -bn1 | grep "Cpu(s)" | \
        awk '{print "CPU Usage:", $2 + $4 "%"}' >> "$TEMPFILE"
    cat "$TEMPFILE" >> "$LOGFILE"
    echo "" >> "$LOGFILE"
}

# Memory check no cap
#separate lines for mem and total is unecessary. -gt only handles integers not decimals. 
function checkMemory() {
    echo "Checking memory..." >> "$LOGFILE"
    read mem total <<< $(free -m | awk '/Mem:/ {print $3, $2}')
    perc=$(awk "BEGIN {printf \"%.2f\",($mem/$total)*100}")
    echo "Memory in use is ${perc}%" >> "$LOGFILE"
	perc_int=$(printf "%.0f" "$perc") 
    if [ "$perc_int" -gt "85" ]; then
        echo "WARNING:Too high!" >> "$LOGFILE"
    else
        echo "Looks Good!" >> "$LOGFILE"
    fi
    echo "" >> "$LOGFILE"
}

# Disk check what can you yeet
#pointless for loop.
function checkDisk() {
    echo "Checking disk usage..." >> "$LOGFILE"
   df -h | awk '$1 ~ /^\// {print "Disk:", $1, "Used:", $5}' >> "$LOGFILE"
    echo "" >> "$LOGFILE"
}

# high key network test
#ANOTHER_TEMP was no longer a variable.Vague wording needed fixing 
function checkNetwork() {
    echo "Pinging google.com to test network..." >> "$LOGFILE"
    ping -c 1 google.com > "$TEMPFILE" 2>&1
    if grep -q "1 received" "$TEMPFILE"; then
        echo "Network Appears Online!" >> "$LOGFILE"
    else
        echo "Ping Failed. Network Offline." >> "$LOGFILE"
    fi
    echo "" >> "$LOGFILE"
}

# low key fire
#echo is unecessary the message just shows up at the end.
function summarize() {
    cat "$LOGFILE"

}

# Health check that slays
#sleep command makes it run slower for no apparent reason.summarize function is gone and needs to be removed.
function main() {
    echo "Starting health check." >> "$LOGFILE"
    headerWriter
    checkCPU
    checkMemory
    checkDisk
    checkNetwork
	summarize
    echo "Done! Health check complete!" >> "$LOGFILE"
}

# Script only works with this running. Don't delete
#YOLO
#Delete everything but the call for main function. for loop makes it run again.
main


# Clanker
#doesn't need fixing just exits the script.
exit 0
