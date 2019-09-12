FROM bluerain/policr:samrt


ARG APP_HOME=/home/policr


RUN mkdir "$APP_HOME" && \
    ln -s "$APP_HOME/sam" /usr/local/bin/sam


COPY bin $APP_HOME


WORKDIR $APP_HOME


ENV POLICR_ENV=prod
