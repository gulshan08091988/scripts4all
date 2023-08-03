#####################################################################################################
#                                                                                                   #
# Script Name: Volt_purge_pro.sh                                                                    #
#                                                                                                   #
# Description: This script is used to purge data                                                    #
# Note:- TABLE on which you are performing bulk deletion needs to be partitioned.
#                                                                                                   #
# Owner: Gulshan Sharma                                                                             #
# Email Id: gsharma@voltactivedata.com                                                              #
# Mobile Number: +918800786640                                                                      #
#                                                                                                   #
#####################################################################################################
if [ -e ../../bin/voltdb ]; then
    # assume this is the examples folder for a kit
    VOLTDB_BIN="$(dirname $(dirname $(pwd)))/bin"
elif [ -n "$(which voltdb 2> /dev/null)" ]; then
    # assume we're using voltdb from the path
    VOLTDB_BIN=$(dirname "$(which voltdb)")
else
    echo "Unable to find VoltDB installation."
    echo "Please add VoltDB's bin directory to your path."
    echo "below is possible example"
    echo "export PATH=/Users/gulshansharma/Downloads/voltdb-ent-9.3.15/bin:$PATH"
    exit -1
fi

logfile=/Users/gulshansharma/Desktop/Customer/invoations/manualcleanup.`date +"%Y-%m-%d"`
option=$1
case $option in
CREATETASK)
read -p "Enter procedure name: " proc_name

# Prompt user whether to delete data with the same column name and pattern on multiple tables
read -p "Do you want to delete data with the same column name and pattern on multiple tables (y/n)? " choice

if [[ $choice =~ ^[yY]$ ]]; then
    # Prompt user for table names, column name, and data pattern
    read -p "Enter table names (separated by space): " tables
    read -p "Enter column name: " column
    read -p "Enter data pattern: " pattern

    # Construct SQL stored procedure using a for loop to loop through each table and generate a delete statement
    dproc="file -inlinebatch END_OF_2ND_BATCH\n"
    dproc+="CREATE PROCEDURE $proc_name DIRECTED\nAS BEGIN\n"
    for table in $tables; do
        dproc+="  DELETE FROM $table WHERE $column=?;\n"
    done
    dproc+="END;\n"
    dproc+="END_OF_2ND_BATCH"
    read -p "Do you want to continue loading the procedure $proc_name into database (y/n)? " choice1
    if [[ $choice1 =~ ^[yY]$ ]]; then
        echo "$dproc" > "$proc_name.sql"
        count=`echo $dproc|grep -v grep|grep -i "DELETE FROM"|sort|wc -l`
	echo "count is $count"
        echo "loading procedure into voltdb"
        sqlcmd < "$proc_name.sql"
        read -p "Do you want to continue scheduling task (y/n)? " choice2

        if [[ $choice2 =~ ^[yY]$ ]]; then
            str="$pattern"
            for (( i=1; i<=$count; i++ ))
            do
              if [ $i -eq 1 ]
              then
             list="$str"
             else
             list="$list,$str"
		echo "$list"
             list=`echo $list | sed "s/,/','/g"`
		echo "$list"
             fi
           done

            # Prompt user for task names, hour and minute
            ctime=`sqlcmd --query="select now from $tables limit 1;"`
            echo "current time is $ctime"
            read -p "Enter task name: " task
            read -p "Enter hour for manualcleanup task: " hour
            read -p "Enter minute for manualcleanup task: " minute
            
            # Escape single quotes in pattern variable
            createtaskquery="CREATE TASK $task ON SCHEDULE CRON 0 $minute $hour * * * PROCEDURE $proc_name WITH ('$list') RUN ON PARTITIONS;"
            
            echo "${createtaskquery}" | sqlcmd
        else
            echo "Customer do not want to schedule task, hence exit."
        fi
    else
        echo "Exit, no need to load $proc_name into database."
    fi
else 
    # Prompt user for table name, column name, and data pattern
    read -p "Enter table name: " table
    read -p "Enter column name: " column
    read -p "Enter data pattern: " pattern

    # Construct SQL stored procedure to delete data based on provided parameters
    nproc="file -inlinebatch END_OF_2ND_BATCH\n"
    nproc+="CREATE PROCEDURE $proc_name DIRECTED\nAS BEGIN\n"
    nproc+="  DELETE FROM $table WHERE $column=?;\n"
    nproc+="END;\n"
    nproc+="END_OF_2ND_BATCH"
    echo "$nproc"
    read -p "Do you want to continue loading the procedure $proc_name into database (y/n)? " choice4
    if [[ $choice4 =~ ^[yY]$ ]]; then
        echo "$nproc" > "$proc_name.sql"
        echo "loading procedure into voltdb"
        sqlcmd < "$proc_name.sql"
        read -p "Do you want to continue scheduling task (y/n)? " choice5

        if [[ $choice5 =~ ^[yY]$ ]]; then

            # Prompt user for task names, hour and minute
            echo "current time is $(date)"
            read -p "Enter task name: " task
            read -p "Enter hour for manualcleanup task: " hour
            read -p "Enter minute for manualcleanup task: " minute
            createtaskquery1="CREATE TASK $task ON SCHEDULE CRON 0 $minute $hour * * * PROCEDURE $proc_name WITH ('$pattern') RUN ON PARTITIONS;"
            echo "${createtaskquery1}" | sqlcmd
        else
            echo "Nothing to do."
        fi
    else
        echo "Exit, no need to load $proc_name into voltdb."
    fi
fi
;;

DISABLETASK)
	read -p "Enter Task name : " Task
        disabletaskquery="ALTER TASK $Task DISABLE;"
	#echo "${disabletaskquery}" | sqlcmd --user=${user} --password=${pass} --servers=${host} --port=${port} >>${logfile}
	echo "${disabletaskquery}" | sqlcmd
	;;

DROPTASK)
	read -p "Enter Task name : " Task
        droptaskquery="DROP TASK $Task;"
	#echo "${droptaskquery}" | sqlcmd --user=${user} --password=${pass} --servers=${host} --port=${port} >>${logfile}
	echo "${droptaskquery}" | sqlcmd
	;;
	*)
                echo "Invalid option $option, valid options are CREATETASK, DISABLETASK, DROPTASK"
        ;;
esac
