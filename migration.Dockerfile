FROM bluerain/policr:build


ARG APP_HOME=/code


RUN mkdir #APP_HOME


COPY . $APP_HOME


RUN shards
    

WORKDIR $APP_HOME
