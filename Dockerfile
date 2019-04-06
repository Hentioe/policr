FROM bluerain/policr:runtime


ARG APP_HOME=/home/policr


RUN ln -s "$APP_HOME/policr" /usr/local/bin/policr && \
    mkdir /data


COPY bin $APP_HOME
COPY public "$APP_HOME/public"


WORKDIR $APP_HOME


ENTRYPOINT policr --prod --dpath /data
