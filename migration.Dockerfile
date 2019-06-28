FROM bluerain/policr:build


ARG APP_HOME=/code


RUN mkdir $APP_HOME


COPY . $APP_HOME


WORKDIR $APP_HOME


RUN shards
