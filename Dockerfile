FROM bluerain/crystal:runtime


ARG APP_HOME=/home/policr


RUN ln -s "$APP_HOME/policr" /usr/local/bin/policr


COPY bin $APP_HOME
COPY public "$APP_HOME/public"


WORKDIR $APP_HOME


ENTRYPOINT policr --prod
