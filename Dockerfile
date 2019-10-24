FROM bluerain/policr:app-runtime


ARG APP_HOME=/home/policr


RUN mkdir "$APP_HOME" && \
    ln -s "$APP_HOME/policr" /usr/local/bin/policr && \
    mkdir /data && \
    ln -s /data "$APP_HOME/data"


COPY bin $APP_HOME
COPY static "$APP_HOME/static"
COPY locales "$APP_HOME/locales"
COPY texts "$APP_HOME/texts"


WORKDIR $APP_HOME


VOLUME ["/data"]


EXPOSE 8080


ENV POLICR_ENV=prod
ENV POLICR_DATABASE_HOST=/data


ENTRYPOINT policr --prod dpath=/data port=8080
