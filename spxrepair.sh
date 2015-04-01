# ************************************************************************************** #
#
#       Name: spxrepair.sh
#
#             Detect and repair out-of-sync errors in Shareplex.
#             Examines the result of "show sync" on a target node and then issues the
#             necessary repair commands on the source. Compatible with RAC.
#
#    Prereqs: Passwordless ssh between all nodes of the target and source.
#             A shared directory accessible to all target and source nodes.
#             A "header file" containing environment settings for running sp_ctrl on the
#             source.
#
#      Usage: Call the script from cron on the target, specifying the source and target
#             SIDs used by Shareplex, the shared directory for logging and writing the
#             repair scripts, the FQN of a header file, and a comma-delimited list of
#             source nodes. Optionally, email addresses for notifications and failure
#             messaging and a log cleanup flag.
#
#      Notes: The header file should end with the following line:
#             $SP_SYS_PRODDIR/bin/sp_ctrl <<EOF
#             Repair commands will be appended after it and the call completed with EOF.
#
# Created by: Sean Scott, Bodybuilding.com
#    Created: 2015/01/22
#
# Updated by: Sean Scott, Bodybuilding.com
#    Updated: 2015/03/31
#             Removed technical debt, cleaned up code.
#
# ************************************************************************************** #

# Set the Oracle environment:
. $HOME/dbbatch.sh
. $DBA/functions.sh
# Set the Shareplex environment:
. $DBA/splex/spxenv.sh
. $DBA/splex/spxfunctions.sh

#****************************************************************
# Functions
#****************************************************************
error()
{
  echo "$@" 1>&2
  if [ "$fmail" ]
    then mailto $fmail "$@" "Fatal error from $PROGRAM on $machine in $BBENV"
  fi
  exit 1
}

usage()
{
  version
  echo "usage: $PROGRAM -s source_SPX_sid -t target_SPX_sid "
  echo "                -l log_directory -n source_nodelist -a header_file "
  echo "                [-e notification_email] [-f failure_email] "
  echo "                [--clean] "
  echo " "
  echo "Arguments:"
  echo "   -s source_SPX_sid     Shareplex SID of the source database "
  echo "   -t target_SPX_sid     Shareplex SID of the target database "
  echo "   -l directory          Shared SPX directory to store repair files "
  echo "   -n source_nodelist    Comma-delimited list of source nodes "
  echo "   -a header_file        Full path and file name for file containing script "
  echo "                         headers, for creating the repair script "
  echo " "
  echo "Optional arguments: "
  echo "   -e notification_email Comma-delimited list of emails for notification of a repair \(target\) "
  echo "   -f failure_email      Comma-delimited list of emails to notify if errors "
  echo "   --clean               Remove files on successful repair "
  echo " "

}

usage_and_exit()
{
  usage
  exit $1
}

version()
{
  echo " "
  echo "$PROGRAM version $VERSION"
  echo " "
}

# Set up the environment. Define default values here.
PROGRAM=`basename $0`
VERSION=1.2
basename=spxrepair
clean=
email=
fmail=
header_file=
machine=$BBHOST
nodelist=
repair_dir=
sid_source=
sid_target=
headers_written=

# Get command line arguments:
while getoptex "a: clean; e: f: h; help; l: n: s: t: v; ?;" "$@"
do
  case $OPTOPT in
    s                ) sid_source="$OPTARG"  ;;
    t                ) sid_target="$OPTARG"  ;;
    l                ) repair_dir="$OPTARG"  ;;
    n                ) nodelist="$OPTARG"    ;;
    a                ) header_file="$OPTARG" ;;
    e                ) email="$OPTARG"       ;;
    f                ) fmail="$OPTARG"       ;;
    clean            ) clean=1               ;;
    h                ) usage_and_exit 0      ;;
    help             ) usage_and_exit 0      ;;
    '?'              ) usage_and_exit 0      ;;
    v                ) version               ;;
  esac
done
shift $[OPTIND-1]

# Validate command line arguments.

# Set up the environment; warn if an invalid SID is supplied
if [ ! "$sid_source" ]
  then error "A source SID to repair is required"
elif [ ! "$sid_target" ]
  then error "A target SID for show sync is required"
fi

# A local repair directory is required:
if [ ! "$repair_dir" ]
  then error "A local directory for repair files must be supplied"
elif [ ! -d "$repair_dir" ]
  then error "The supplied repair directory does not exist"
elif [ ! -w "$repair_dir" ]
  then error "The supplied repair directory is not writable"
fi

# At least one source node is required.
if [ ! "$nodelist" ]
  then error "At least one source node must be specified"
fi

# A header file is required. It should call whatever environment configs are necessary
# for running Shareplex on the source machine.
if [ ! "$header_file" ]
  then error "A header file must be specified"
elif [ ! -e "$header_file" ]
  then error "The specified header file $header_file does not exist"
elif [ ! -r "$header_file" ]
  then error "The specified header file $header_file is not readable"
fi

# Create the file extensions and files to be used:
now=`date '+%y-%m-%d_%H-%M-%S'`
repairfile=$repair_dir/$basename.$now.sh
logfile=$repair_dir/$basename.$now.log
resultfile=$repair_dir/$basename.$now.out

# Flag to determine if we've already written headers. This saves the need for creating 
# (and subsequently deleting) the repair and log files if there's nothing to repair:
headers_written=

# Loop through the list of nodes the user has supplied and see where sp_cop is running:
set -f; IFS=,
for node in $nodelist
do
   nodecheck=`ssh $node ps -ef | grep sp_cop | grep -v grep | wc -l`
   if [ "$nodecheck" == 1 ]
     then node_source=$node
          # If sp_cop is discovered running on a node, break the loop:
          break;
   fi
done
set =f; unset IFS

# Make sure there was a node returned:
if [ ! "$node_source" ]
  then error "Could not obtain the SPX source node from $machine in $BBENV"
fi

# On the target, loop through the results of the "show sync" command to get all tables
# that may be out of sync and build the repair and log files. Pull just the fields we need
# to discover the table and generate a notification email:
sp_ctrl show sync on $sid_target 2>&1 | grep 'out of sync' | awk '{print $1,$3,$9,$11,$12}' | while read line
do
  # Is this the first time through? If so, write headers.
  if [ ! "$headers_written" ]
    then cat $header_file > $repairfile
         if [ $? -ne 0 ]
           then error "Could not create the repair script file"
         fi
         # Add headers to the notification file:
         echo "The following tables were out of sync on $machine in $BBENV. A repair has been started" > $logfile
         echo "on host $node_source for database $sid_source." >> $logfile
         echo "" >> $logfile
         if [ $? -ne 0 ]
           then error "Could not create the email notification file"
         fi
         # Set the header flag so that we don't write them again:
         headers_written=1
  fi
  # Add the table to be repaired to the repair file:
  echo "$line" | awk '{print "repair " $2}' >> $repairfile
  # Create a verbose entry for the table:
  echo "$line" | awk '{print $1 " rows out of sync in " $2 " for queue " $3 " as of " $4 " " $5}' >> $logfile
done

# If a repair file was created, there are tables to be repaired. Run the repair script on the source via ssh:
if [ -e "$repairfile" ]
  then echo "EOF" >> $repairfile
       chmod 750 $repairfile
       ssh $node_source $repairfile > $resultfile
       if [ $? -ne 0 ]
         then error "Repair failed on host $node_source for SID $sid_source for script $repairfile"
       fi
       if [ "$email" ]
         then echo "" >> $logfile
              cat $resultfile | grep -v '^$' | grep -v '^*' >> $logfile
              mailto $email $logfile "Shareplex repair started from $machine in $BBENV" FILE
       fi
       # Delete the repair file.
       rm $repairfile
       if [ $? -ne 0 ]
         then error "Could not remove the repair file $repairfile from $machine in $BBENV"
       fi
       rm $resultfile
       if [ $? -ne 0 ]
         then error "Could not remove the result file $resultfile from $node_source in $BBENV"
       fi
       # Leave the log file unless the user has requested the "clean" option:
       if [ "$clean" ]
         then rm $logfile
             if [ $? -ne 0 ]
               then error "Could not remove the log file $logfile from $machine in $BBENV"
             fi
       fi
fi

exit 0
