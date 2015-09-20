#!/bin/bash 
# Configuration

#Change to location of your minecraft_server.jar
MC_PATH=/minecraft/bukkit/
#Change to preferred name of screen
SCREEN_NAME="minecraft"
#Change to memory allocation, in gigabytes
MEMALOC=4
#Configure if you wish to connect to the screen when running script: 1 is true, 0 is false
DISPLAY_ON_LAUNCH=1
#change to name of the .jar you wish to run
SERVER_JAR=minecraft_server.jar
#change to name of world
WORLD_NAME="tehbeard"

LOG_TDIR=$MC_PATH/logs
#change to how many days of logs you wish to unpack when running 'logs' or 'logs clean'
LOGS_DAYS=7

# End of configuration

ONLINE_OLD=`ps -ef | grep $SCREEN_NAME | wc -l`
ONLINE=$(($ONLINE_OLD-3))
echo $ONLINE

display() {
	screen -x $SCREEN_NAME
}

server_launch() {
	echo "Launching minecraft server..."
    cd $MC_PATH
    echo "make sure to read eula.txt before playing!"
    screen -m -d -S $SCREEN_NAME /usr/jdk1.7.0_40/bin/java -server -Xms2048m -Xmx5120m -XX:PermSize=256m -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -jar $SERVER_JAR nogui; sleep 1
}

server_stop() {
	echo "Stopping minecraft server..."
	screen -S $SCREEN_NAME -p 0 -X stuff "`printf "save-all\r"`"; sleep 30
	screen -S $SCREEN_NAME -p 0 -X stuff "`printf "stop\r"`"; sleep 5
}

if [ $# -gt 0 ]
then
	case $1 in

	# Server Status ###############################################################
	"status")
		if [ $ONLINE -eq 1 ]
		then
			echo "Minecraft server seems ONLINE."
		else 
			echo "Minecraft server seems OFFLINE."
		fi;;

	# Start the Server ############################################################
	"start")
		if [ $ONLINE -eq 1 ]
		then
			echo "Server seems to be already running!"
			case $2 in
			"force")
				echo "Forcing server start..."
				echo "Killing server processes..."
				kill `ps -n | grep $SERVER_JAR | grep -v "grep" | tr -s ' ' | cut -d " " -f 2`
				rm -fr $MC_PATH/*.log.lck 2> /dev/null/
				echo "Done."
				server_launch
				if [ $DISPLAY_ON_LAUNCH -eq 1 ]
				then
					display
				fi;;
			esac
		else
			server_launch
			if [ $DISPLAY_ON_LAUNCH -eq 1 ]
			then
				display
			fi
		fi;;

	# Server Shutdown #############################################################
	"stop")
		if [ $ONLINE -eq 1 ]
		then
                        case $2 in
                        "warn")
				echo "Counting down 2 minutes to server shutdown..."
                                screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will shutdown in 2 minutes, restarts take only a few minutes!\r"`"; sleep 90
                                screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will shutdown in 30 seconds, restarts take only a few minutes!\r"`"; sleep 20
                                screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will shutdown in 10s !\r"`"; sleep 10;;
                        esac
			server_stop
			echo "Server stopped."
		else
			case $2 in
			"force")
				echo "Killing server processes..."
				kill `ps -n | grep $SERVER_JAR | grep -v "grep" | tr -s ' ' | cut -d " " -f 2`
				rm -fr $MC_PATH/*.log.lck 2> /dev/null/
				echo "Done.";;
			*)
				echo "Server seems to be offline...";;
			esac
		fi;;

	# Server Shutdown - Maintenance ###############################################
	"maint")
		if [ $ONLINE -eq 1 ]
		then
				echo "Counting down 2 minutes to server shutdown..."
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will shutdown in 2 minutes for maintenance, please check IRC/webchat and forums for updates!\r"`"; sleep 90
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will shutdown in 30 seconds, please check IRC/webchat and forums for updates!\r"`"; sleep 20
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will shutdown in 10s !\r"`"; sleep 10
		server_stop
		echo "Server stopped."
		fi;;

	# Restart the Server ##########################################################
	"bounce")
                if [ $ONLINE -eq 1 ]
                then
                        case $2 in
                        "warn")
				echo "Counting down 2 minutes to server shutdown..."
                                screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will restart in 2 minutes, restarts take only a few minutes!\r"`"; sleep 90
                                screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will restart in 30 seconds, restarts take only a few minutes!\r"`"; sleep 20
                                screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will restart in 10s !\r"`"; sleep 10;;
                        esac
                        server_stop
			echo "Server stopped."
                        sleep 20
                fi

                server_launch

                if [ $DISPLAY_ON_LAUNCH -eq 1 ]
                then
                        display
                fi;;

	# Boop Beep! ##################################################################
	"beep")
                if [ $ONLINE -eq 1 ]
                then
                      screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say beep boop\r"`"; sleep 1
                fi;;

        # Bukkit Version ##############################################################
        "version")
                if [ $ONLINE -eq 1 ]
                then
                      screen -S $SCREEN_NAME -p 0 -X stuff "`printf "version\r"`"; sleep 1
                fi
		tail -n 500 /logs/server.log | egrep version | awk '{print $11 $12;}' | uniq > $MC_PATH/version.txt;;

        # Online Players ##############################################################
        "list")
                if [ $ONLINE -eq 1 ]
                then
                      screen -S $SCREEN_NAME -p 0 -X stuff "`printf "list\r"`"; sleep 1

                fi;;

	# Logs ########################################################################
	"logs")
		mkdir -p $LOG_TDIR
		cd $LOG_TDIR

		case $2 in
		"clean")
			DATE=$(date +%d-%m --date "$LOGS_DAYS day ago")
			if [ -e logs-$DATE ]
			then
				mkdir -p $BKUP_PATH/logs
				mv logs-$DATE $BKUP_PATH/logs/
			fi;;
		esac

		DATE=$(date +%d-%m)
		LOG_NEWDIR=logs-$DATE
		if [ -e $LOG_TDIR/$LOG_NEWDIR ]
		then
			rm $LOG_TDIR/$LOG_NEWDIR/*
		else
			mkdir $LOG_TDIR/$LOG_NEWDIR
		fi

		DATE=$(date +%d-%m-%Hh%M)
		LOG_TFILE=logs-$DATE.log

		if [ $SERVERMOD -eq 1 ]
		then
			if [ $ONLINE -eq 1 ]
			then
				LOG_LCK=$(basename $MC_PATH/logs/*.log.lck .log.lck)
				echo "Found a log lock : $LOG_LCK"
			else
				LOG_LCK=""
			fi

			cd $MC_PATH/logs/
			for i in *
			do
				if [ $i != $LOG_LCK.log.lck ] 
				then
					cat $i >> $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE
					if [ $i != $LOG_LCK.log ]
					then
						rm $i
					fi
				fi
			done
		else
			cd $MC_PATH
			cat server.log >> $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE
		fi

		if [ -e $LOG_TDIR/ip-list.log ]
		then
			cat $LOG_TDIR/ip-list.log | sort | uniq > $LOG_TDIR/templist.log
		fi

		cat $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE | egrep '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.+logged in'  | sed -e 's/.*\[INFO\]\s//g' -e 's/\[\//\t/g' -e 's/:.*//g' >> $LOG_TDIR/templist.log
		cat $LOG_TDIR/templist.log | sort | uniq -w 4 > $LOG_TDIR/ip-list.log
		rm $LOG_TDIR/templist.log

		cat $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE | egrep 'logged in|lost connection' | sed -e 's/.*\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).\[INFO\].\([a-zA-Z0-9_]\{1,\}\).\{1,\}logged in/\1\t\2 : connected/g' -e 's/.*\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).\[INFO\].\([a-zA-Z0-9_]\{1,\}\).lost connection.*/\1\t\2 : disconnected/g' >> $LOG_TDIR/$LOG_NEWDIR/connexions-$DATE.log

		cat $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE | egrep '<[a-zA-Z0-9_]+>|\[CONSOLE\]' | sed -e 's/.*\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).\[INFO\]./\1 /g' >> $LOG_TDIR/$LOG_NEWDIR/chat-$DATE.log

		cat $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE | egrep 'Internal exception|error' | sed -e 's/.*\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).\[INFO\]./\1\t/g' >> $LOG_TDIR/$LOG_NEWDIR/errors-$DATE.log
	;;

        # Save the Map ################################################################
        "save")
                        if [ $ONLINE -eq 1 ]
                        then
                                echo "Server running, warning players : save in 10s."
                                screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Saving the map in 10s\r"`"; sleep 10
                                screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Now saving the map...\r"`"
                                echo "Issuing save-all command, wait 30s..."
                                screen -S $SCREEN_NAME -p 0 -X stuff "`printf "save-all\r"`"; sleep 30
                                screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Save complete.\r"`"
			else
                        	echo "Server is not running, skipping"
                        fi;;

        # Default Output ##############################################################
	*)
		echo "Usage : minecraft <status | start [force] | stop | bounce [warn] (no backup) | maint (warns then shutdown) | save | logs [clean] | beep | stats | version>";
	esac

else
	if [ $ONLINE -eq 1 ]
	then
		display
	else
		echo "Minecraft server seems to be offline..."
	fi
fi
exit 0

