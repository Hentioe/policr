FROM bluerain/crystal:runtime


RUN apt update && \
    apt install librocksdb4.1 libyaml-0-2 -y && \
    rm -rf /var/lib/apt/lists/*  && \
    rm -rf /var/lib/apt/lists/partial/*