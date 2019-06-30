FROM bluerain/policr:runtime


ARG APP_HOME=/home/policr


RUN ln -s "$APP_HOME/policr" /usr/local/bin/policr && \
    mkdir /data \
    ln -s /data "$APP_HOME/data"


COPY bin $APP_HOME
COPY public "$APP_HOME/public"
COPY locales "$APP_HOME/locales"


WORKDIR $APP_HOME


VOLUME ["/data"]


EXPOSE 8080


ENV POLICR_ENV=prod


ENTRYPOINT policr --prod --dpath /data -p 8080
