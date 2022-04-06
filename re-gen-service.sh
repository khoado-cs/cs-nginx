#!/bin/sh
id -u

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

export PAR_PATH=$(pwd)
export PATH_SERVICE="/etc/systemd/system"
export PREFIX=$PAR_PATH/nginx


cat > $PAR_PATH/nginx.service <<- EOM
[Unit]
Description=nginx rapidcode - high performance web server
Documentation=http://nginx.org/en/docs/
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=$PREFIX/logs/nginx.pid
ExecStartPre=$PREFIX/sbin/nginx -t
ExecStart=$PREFIX/sbin/nginx -c $PREFIX/conf/nginx.conf
ExecReload=$PREFIX/sbin/nginx -s reload
ExecStop=$PREFIX/sbin/nginx -s QUIT $MAINPID
PrivateTmp=true
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOM

sudo chmod -R 777 $PAR_PATH/nginx.service

cat $PAR_PATH/nginx.service > $PATH_SERVICE/ngx-rapidcode.service
# sudo echo $FILE_CONTENT > /lib/systemd/system/shellscript.service
sudo systemctl daemon-reload 

sudo systemctl enable ngx-rapidcode.service

sudo systemctl start ngx-rapidcode.service

sudo systemctl restart ngx-rapidcode.service
