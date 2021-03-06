#!/bin/sh

export PAR_PATH=$(pwd)
export INSTALL_PATH="/etc/rapidcode"
export PATH_SERVICE="/etc/systemd/system"
export PREFIX=$INSTALL_PATH/nginx
export USER_RC="www-rc"
export LUAPAT="$PREFIX/luajit"
#build luajit
cd $PAR_PATH/dependent/luajit2-2.1
make && sudo make install PREFIX=$LUAPAT

export LUAJIT_LIB=$LUAPAT/lib
export LUAJIT_INC=$LUAPAT/include/luajit-2.1
#end build luajit

cd $PAR_PATH/dependent/lua-resty-core
make install PREFIX=$LUAPAT
cd $PAR_PATH/dependent/lua-resty-lrucache
make install PREFIX=$LUAPAT

useradd --system --no-create-home --shell=/sbin/nologin $USER_RC

cd $PAR_PATH/bin
./configure --prefix=$PREFIX --user=$USER_RC --with-http_ssl_module --with-http_v2_module --with-threads \
--with-file-aio --with-http_auth_request_module --with-mail --with-mail_ssl_module --with-stream \
--with-stream_ssl_module --add-module=$PAR_PATH/modules/lua-nginx-module \
--add-module=$PAR_PATH/dependent/ngx_devel_kit --with-ld-opt="-Wl,-rpath,$LUAPAT"

make

make install

make clean

#creaet service for linux
cat > $INSTALL_PATH/nginx.service <<- EOM
[Unit]
Description=nginx rapidcode - high performance web server
Documentation=http://nginx.org/en/docs/
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=$PREFIX/logs/nginx.pid
ExecStartPre=$PREFIX/sbin/nginx -t
ExecStart=$PREFIX/sbin/nginx -c $PREFIX/conf/nginx.conf -p $PREFIX
ExecReload=$PREFIX/sbin/nginx -s reload
ExecStop=$PREFIX/sbin/nginx -s QUIT $MAINPID
PrivateTmp=true
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOM

sudo rm -r $PREFIX/conf/sites-enabled/default.conf

sudo ln -s $PREFIX/conf/sites-available/default.conf $PREFIX/conf/sites-enabled/

sudo chown -R $USER_RC $PREFIX
sudo chown -R $USER_RC /var/www

sudo chmod -R 777 $PREFIX
sudo chmod -R 777 $INSTALL_PATH/nginx.service

cat $INSTALL_PATH/nginx.service > $PATH_SERVICE/ngx-rapidcode.service

sudo systemctl daemon-reload 

sudo systemctl enable ngx-rapidcode.service

sudo systemctl start ngx-rapidcode.service

sudo systemctl restart ngx-rapidcode.service