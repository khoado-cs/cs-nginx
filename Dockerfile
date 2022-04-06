FROM debian:stable as Builder
LABEL maintainer Khoa Do <dokimdangkhoa@gmail.com>

ENV PAR_PATH /usr/local/src
ENV INSTALL_PATH /usr/local/src/rapidcode
ENV PATH_SERVICE /etc/systemd/system
ENV PREFIX ${INSTALL_PATH}/nginx
ENV USER_RC www-rc
ENV LUAPAT ${PREFIX}/luajit

WORKDIR /usr/local/src

COPY . .

RUN apt-get update
RUN apt-get install -y dpkg-dev libpcre3-dev zlib1g-dev libssl-dev

#build luajit
WORKDIR /usr/local/src/dependent/luajit2-2.1
RUN make && make install PREFIX=${LUAPAT}

ENV LUAJIT_LIB ${LUAPAT}/lib
ENV LUAJIT_INC ${LUAPAT}/include/luajit-2.1

WORKDIR  /usr/local/src/dependent/lua-resty-core
RUN make install PREFIX=${LUAPAT}
WORKDIR /usr/local/src/dependent/lua-resty-lrucache
RUN make install PREFIX=${LUAPAT}

RUN useradd --system --no-create-home --shell=/sbin/nologin ${USER_RC}

WORKDIR /usr/local/src/bin
RUN ./configure --prefix=${PREFIX} --sbin-path=/usr/sbin/nginx --user=${USER_RC} --with-http_ssl_module --with-http_v2_module --with-threads \
--with-file-aio --with-http_auth_request_module --with-mail --with-mail_ssl_module --with-stream \
--with-stream_ssl_module --add-module=${PAR_PATH}/modules/lua-nginx-module \
--add-module=${PAR_PATH}/dependent/ngx_devel_kit --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}"

RUN make

RUN make install

RUN make clean

WORKDIR ${PREFIX}

RUN ln -s ./conf/sites-available/default.conf ./conf/sites-enabled/

CMD ["nginx","-g" , "daemon off;"]

EXPOSE 80/tcp 443/tcp 1935/tcp
