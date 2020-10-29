#!/data/data/com.termux/files/usr/bin/bash
if [ ! -f "export.sh" ]; then
cat <<EOF >export.sh
#!/data/data/com.termux/files/usr/bin/sh
export REDIS_PORT="46379"
export USE_CELERY="false"
export CELERY_WORKER_COUNT="2"
export RUN_FILEBROWSER="true"
export FILEBROWSER_PORT="9998"
export OS_PREFIX="LinuxArm"
export FILEBROWSER_BASEURL="/filebrowser"
export SJVA_RUNNING_TYPE="termux"
EOF
fi

if [ -f "export.sh" ]; then
    echo "Run export.sh start"
    chmod 777 export.sh
    sh export.sh
    echo "Run export.sh end"
fi

if [ -f "pre_start.sh" ]; then
	echo "Run pre_start.sh start"
	chmod 777 pre_start.sh
	sh pre_start.sh
	echo "Run pre_start.sh end"
fi

export REDIS_PORT="46379"
export USE_CELERY="false"
export CELERY_WORKER_COUNT="2"
export RUN_FILEBROWSER="true"
export FILEBROWSER_PORT="9998"
export OS_PREFIX="LinuxArm"
export FILEBROWSER_BASEURL="/filebrowser"
export SJVA_RUNNING_TYPE="termux"

if [ ${USE_CELERY} == "true" ]; then
    nohup redis-server --port ${REDIS_PORT} > /dev/null 2>&1 &
    echo "Start redis-server port:${REDIS_PORT}"
fi

if [ ${RUN_FILEBROWSER} == "true" ] && [ -f ./bin/${OS_PREFIX}/filebrowser ]; then
    chmod +x ./bin/${OS_PREFIX}/filebrowser
    if [ -z "${FILEBROWSER_BASEURL}" ]; then
        nohup ./bin/${OS_PREFIX}/filebrowser -a 0.0.0.0 -p ${FILEBROWSER_PORT} -r ~/ -d ./data/db/filebrowser.db > /dev/null 2>&1 &
    else
        nohup ./bin/${OS_PREFIX}/filebrowser -a 0.0.0.0 -p ${FILEBROWSER_PORT} -r ~/ -d ./data/db/filebrowser.db -b ${FILEBROWSER_BASEURL} > /dev/null 2>&1 &
    fi
    echo "Start Filebrowser. port:${FILEBROWSER_PORT}"
fi

COUNT=0
while [ 1 ];
do
    find . -name "index.lock" -exec rm -f {} \;
    git reset --hard HEAD
    git pull
    chmod 777 .
    chmod -R 777 ./bin

    if [ ! -f "./data/db/sjva.db" ]; then
        python3 sjva.py 0 ${COUNT} init_db
    fi

    if [ ${USE_CELERY} == "true" ]; then
        sh worker_start.sh &
        echo "Run celery-worker.sh"
        python3 sjva.py 0 ${COUNT}
    else
        python3 sjva.py 0 ${COUNT} no_celery
    fi
    
    RESULT=$?
    echo "PYTHON EXIT CODE : ${RESULT}.............."
    if [ "$RESULT" = "0" ]; then
        echo 'FINISH....'
        break
    else
        echo 'REPEAT....'
    fi 
    COUNT=`expr $COUNT + 1`
done 

if [ "${RUN_FILEBROWSER}" == "true" ]; then
    ps -eo pid,args | grep filebrowser | grep -v grep | awk '{print $1}' | xargs -r kill -9
fi
sv down php-fpm
sv down nginx
