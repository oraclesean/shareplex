error()
{
  echo "$@" 1>&2
  exit 1
}

set_env()
{
  source ./spxenv.sh
}

check_shareplex()
{
 check=`ps -ef | grep "sp_cop" | grep -v grep | wc -l`
}

stop_shareplex()
{
  set_env
  now=`date '+%m/%d/%y %H:%M:%S'`
  echo "Stopping Shareplex at ${now}." | tee -a $logfile
  echo "This will take a few moments. Please be patient..." | tee -a $logfile

  $SP_SYS_PRODDIR/bin/sp_ctrl <<EOF >> $logfile
  shutdown
  exit
EOF

  EXITCODE=$?
  check_shareplex

    if [ $EXITCODE == 1 ] || [ $check -gt 0 ]
      then error "There was a problem stopping Shareplex!" | tee -a $logfile
    fi

  now=`date '+%m/%d/%y %H:%M:%S'`
  echo "Shareplex stopped successfully at ${now}." | tee -a $logfile
  exit 0
}

start_shareplex ()
{
  set_env
  now=`date '+%m/%d/%y %H:%M:%S'`
  echo "Starting Shareplex at ${now}." | tee -a $logfile
  echo "This will take a few moments. Please be patient..." | tee -a $logfile
  templog=$(mktemp)
  sh <<EOF > $templog
  $SP_SYS_PRODDIR/bin/sp_cop -u${BBHOST} &
EOF

  for ck in {1..12}
  do
    # Check every 5 seconds for up to a minute to see that sp_cop has started.
    sleep 5
    check_shareplex
    if [ $check -eq 1 ]
    then
      now=`date '+%m/%d/%y %H:%M:%S'`
      echo "Shareplex startup completed at ${now}." | tee -a $logfile
      # At this point the sp_cop process has started, but we want the startup
      # log to have all of the information about the startup. Sleep for 15 
      # seconds and then cat the redirected nohup log into the main log file.
      sleep 15
      cat $templog >> $logfile
      exit 0
    fi
    done

  # If we get here, the startup didn't happen within 60 seconds.
  # Give up and throw an error (exit 1) 
  error "There was a problem starting Shareplex!" | tee -a $logfile
}

truncate_shareplex_log()
{
  set_env
  now=`date '+%m/%d/%y %H:%M:%S'`
  echo "Truncating Shareplex log file at ${now}." | tee -a $logfile
  echo "This will take a few moments. Please be patient..." | tee -a $logfile

  $SP_SYS_PRODDIR/bin/sp_ctrl <<EOF >> $logfile
  truncate
  exit
EOF

  EXITCODE=$?
  check_shareplex

    if [ $EXITCODE == 1 ] || [ $check -gt 0 ]
      then error "There was a problem truncating the Shareplex log!" | tee -a $logfile
    fi

  rm $SP_SYS_VARDIR/log/event_log
  rm $SP_
  touch $SP_SYS_VARDIR/log/event_log
  
  now=`date '+%m/%d/%y %H:%M:%S'`
  echo "Shareplex event log truncated at ${now}." | tee -a $logfile
  exit 0
  
}

clean_shareplex()
{
  pkill -9 -f sp_
}
