FROM bluerain/policr:samrt


ARG APP_HOME=/policr


RUN mkdir "$APP_HOME" && \
    mkdir "$APP_HOME/db" && \
    mkdir "$APP_HOME/data" && \
    ln -s "$APP_HOME/sam" /usr/local/bin/sam


COPY bin/sam "$APP_HOME/sam"


WORKDIR $APP_HOME


ENV POLICR_ENV=prod
