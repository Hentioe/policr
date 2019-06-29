FROM crystallang/crystal:0.29.0-build


RUN apt update && \
    apt install librocksdb-dev libsqlite3-dev sqlite3 -y && \
    rm -rf /var/lib/apt/lists/*  && \
    rm -rf /var/lib/apt/lists/partial/*
