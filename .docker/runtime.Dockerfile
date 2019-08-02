FROM bluerain/crystal:runtime


RUN apt update && \
    apt install libsqlite3-0 librocksdb5.17 -y && \
    rm -rf /var/lib/apt/lists/*  && \
    rm -rf /var/lib/apt/lists/partial/*
