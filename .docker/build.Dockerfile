FROM bluerain/crystal:0.31.1-build


RUN apt update && \
    apt install libsqlite3-dev sqlite3 -y && \
    rm -rf /var/lib/apt/lists/*  && \
    rm -rf /var/lib/apt/lists/partial/*
