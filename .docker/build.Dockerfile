FROM crystallang/crystal:0.27.2-build


RUN apt update && \
    apt install librocksdb-dev -y && \
    rm -rf /var/lib/apt/lists/*  && \
    rm -rf /var/lib/apt/lists/partial/*