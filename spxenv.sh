# Customize for your environment.
#
# Get the environment and hostname:
export BBENV=`hostname -d | cut -d"." -f2`
export BBHOST=`hostname -s`
#
export INST_TYPE="rdbms"
export LANG="en_US.UTF-8"
# By convention, our Shareplex SIDs all contain 'spx'. Get the correct local database meta that a) doesn't contain 'spx'
# and b) isn't ASM:
export ORACLE_DBNAME=`grep -v \^# /etc/oratab | grep -v spx | grep -v ASM | cut -d":" -f5`
export ORACLE_SID=`grep $ORACLE_DBNAME /etc/oratab | grep -v \^# | cut -d":" -f1`
export ORACLE_HOME=`grep $ORACLE_DBNAME /etc/oratab | grep -v \^# | cut -d":" -f2`
# Build the rest of the environment:
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export ORACLE_BASE=/oracle
export ORACLE_TERM=vt100
export ORAENV_ASK=NO
# Build the Shareplex variables:
export SP_COP_UPORT=2100
# The Shareplex install directories are NFS mounts and splex is reserved for them. This works in our environment, YMMV:
export SP_INSTALL_DIR=`df -h | grep \/splex | awk '{ print $NF }'`
# Get the ASM sid from the oratab:
export SP_OCT_ASM_SID=`grep ASM /etc/oratab | grep -v \^# | cut -d":" -f1`
# Get the Shareplex SID. spx is reserved for Shareplex in our environment, so this works throughout. YMMV:
export SP_SYS_HOST_NAME=`grep spx /etc/oratab | cut -d":" -f1`
# Version 8
export SP_SYS_PRODDIR=$SP_INSTALL_DIR/product/8
export SP_SYS_VARDIR=$SP_INSTALL_DIR/var
export IW_HOME=$SP_SYS_PRODDIR/util
# Set up the path:
export PATH=$ORACLE_HOME/bin:/shared/dbscripts:/usr/bin:/usr/sbin:/etc:/sbin:/bin:$SP_SYS_PRODDIR/bin
export TNS_ADMIN=$ORACLE_HOME/network/admin
