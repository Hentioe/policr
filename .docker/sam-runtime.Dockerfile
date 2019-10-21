FROM bluerain/crystal:runtime-slim


RUN apt update && \
    apt install libsqlite3-0 sqlite3 -y && \
    rm -rf /var/lib/apt/lists/*  && \
    rm -rf /var/lib/apt/lists/partial/*
