# File used during batch processing to set environment variables used in scripts
export CLIENT=customer
export MACHINE=`uname -n`
export DEFAULT_MAIL=someone@example.com
export DBA_MAIL=dba1@example.com,dba2@example.com
export APP_EMAIL=appuser@example.com
export ALL_MAIL=$DBA_MAIL","$APP_EMAIL
export ORACLE_BASE=/oracle
export ORACLE_HOME=$ORACLE_BASE/product/12.1.0.2/db_home1
export ADR_BASE=$ORACLE_BASE
export NODE=node1
export DBA=/home/oracle/scripts
export LOGS=/home/oracle/logs
export PATH=$ORACLE_HOME/bin:$ORACLE_BASE/product/grid/11.2.0/bin:$DBA:/usr/bin:/usr/sbin:/etc:/sbin:/bin
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib:$ORACLE_HOME/network/jlib
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export ORAENV_ASK=NO
# Skip the prompt for the ORACLE_SID. (Executed only for non-interactive jobs).
if [ "`tty`" != "not a tty" ]
then
        #       Prompt for the desired ORACLE_SID for interactive jobs
        . $ORACLE_HOME/bin/oraenv
fi
# Ensure one (and only one . is in the PATH)
case "$PATH" in
        *.*)            ;;                      # If already in the path?
        *:)             PATH=${PATH}.: ;;       # If path ends in a colon?
        "")             PATH=. ;;               # If path is null?
        *)              PATH=$PATH:. ;;         # If none of the above?
esac
umask 177
export PS_OPTS="-ef"
