#!/bin/bash
#########################################################################
# File Name: run.sh
# Author: meetbill
# mail: meetbill@163.com
# Created Time: 2018-04-27 10:36:55
#########################################################################

ROOT_PATH=`S=\`readlink "$0"\`; [ -z "$S"  ] && S=$0; dirname $S`
cd ${ROOT_PATH}
DISP_NAME="inter_cept"
EXEC_FILE="./sbin/intercept"
MAIN_FILE="intercept"
STDOUT="./__stdout"
# Consts
RED='\e[1;91m'
GREN='\e[1;92m'
WITE='\e[1;97m'
NC='\e[0m'

# Global vailables
PROC_COUNT="0"
function count_proc()
{
    PROC_COUNT=$(ps -ef | grep "$MAIN_FILE" | grep -vc grep)
}
function list_proc()
{
    ps -ef | grep -v grep | grep --color "$MAIN_FILE"
}
function list_proc_pids()
{
    ps -ef | grep "$MAIN_FILE" | grep -v grep | awk '{print $2}'
}

function start_procs()
{
    cept_port=$1
    [[ -z ${cept_port} ]] && echo "not found port" && exit -1
    export LD_LIBRARY_PATH=${ROOT_PATH}/lib:$LD_LIBRARY_PATH
    printf "Starting $DISP_NAME processes"
    count_proc
    if [ $PROC_COUNT \> 0 ]; then
        echo
        list_proc
        echo -e ${RED}"\n[ERROR]" ${NC}"Start $DISP_NAME failed, processes already runing."
        exit -1
    fi

    $EXEC_FILE  -i xgbe0 -F "tcp and src port $cept_port" -d  1>$STDOUT 2>&1 &

    sleep 1
    list_proc
    count_proc
    if [ $PROC_COUNT == 0 ]; then
        echo -e ${RED}"\n[ERROR]" ${NC}"Start $DISP_NAME failed."
        exit -1
    fi

    echo -e ${GREN}"\n[OK]" ${NC}"$DISP_NAME start succesfully."
}

function stop_procs()
{
    printf "Stoping $DISP_NAME"
    count_proc
    if [ ${PROC_COUNT} -eq 0 ]; then
        echo -e ${RED}"\n[ERROR]" ${NC}"$DISP_NAME process not found."
        exit -1
    fi
    
    kill -15 $(list_proc_pids)
    count_proc
    while [ ${PROC_COUNT} -ne 0 ]; do
        printf "."
        sleep 0.2
        count_proc
    done
    echo -e ${GREN}"\n[OK]" ${NC}"$DISP_NAME stop succesfully."
}

function status_procs()
{
    count_proc
    echo -e ${RED}${PROC_COUNT}${NC} "$DISP_NAME processes runing."        
}

MODE=${1}
port=${2}
case ${MODE} in
    "start")
        start_procs $port
        ;;

    "stop")
        stop_procs
        ;;

    "restart")
        stop_procs
        start_procs
        ;;

    "status")
        status_procs
        ;;
    
    *)
        # usage
        echo -e "\nUsage: $0 {start|stop|restart|status}"
        echo -e ${WITE}" start port  "${NC}"Start $DISP_NAME processes."
        echo -e ${WITE}" stop    "${NC}"Kill all $DISP_NAME processes."
        echo -e ${WITE}" restart "${NC}"Kill all $DISP_NAME processes and start again."
        echo -e ${WITE}" status  "${NC}"Show $DISP_NAME processes status.\n"
        exit 1
        ;;
esac
