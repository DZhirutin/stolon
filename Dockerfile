FROM postgres:14.1 AS builder

ENV STOLON_VERSION=v0.17.0

RUN set -ex \
  && apt-get update \
  && apt-get install wget build-essential libkrb5-dev libssl-dev postgresql-server-dev-14 -y 

RUN set -ex \
  && wget -qO - https://github.com/sorintlab/stolon/releases/download/${STOLON_VERSION}/stolon-${STOLON_VERSION}-linux-amd64.tar.gz | tar -C /tmp -xz -f '-' \
  && mv /tmp/stolon-${STOLON_VERSION}-linux-amd64 /tmp/stolon

ENV PG_AUDIT=1.6.1

RUN set -ex \
  && wget -qO - https://github.com/pgaudit/pgaudit/archive/refs/tags/${PG_AUDIT}.tar.gz | tar -C /tmp -xz -f '-' \
  && cd /tmp/pgaudit-${PG_AUDIT} \
  && PG_CONFIG=/usr/lib/postgresql/14/bin/pg_config make install USE_PGXS=1

ENV WAL2JSON_VERSION=2_4
ENV WAL2JSON_URL="https://github.com/eulerto/wal2json/archive/refs/tags/wal2json_${WAL2JSON_VERSION}.tar.gz"

RUN set -ex \
  && wget -O- --no-check-certificate ${WAL2JSON_URL} | tar -C /tmp -zxf - \
  && mv /tmp/wal2json-wal2json_${WAL2JSON_VERSION} /tmp/wal2json \
  && cd /tmp/wal2json \
  && make

ENV WALG_VERSION=v1.1

RUN set -ex \
  && wget -qO - https://github.com/wal-g/wal-g/releases/download/${WALG_VERSION}/wal-g-pg-ubuntu-20.04-amd64.tar.gz | tar -C /tmp -xz -f '-' 

ENV ENVDIR=v1.0.0
ENV ENVDIR_URL="https://github.com/d10n/envdir/releases/download/${ENVDIR}/envdir.linux-amd64.tar.gz"

RUN set -ex \
  && wget -qO - ${ENVDIR_URL} | tar -C /tmp -xz -f '-'

ENV PGCENTER=v0.9.2
ENV PGCENTER_URL="https://github.com/lesovsky/pgcenter/releases/download/${PGCENTER}/pgcenter_0.9.2_linux_amd64.tar.gz"

RUN set -ex \
  && wget -qO - ${PGCENTER_URL} | tar -C /tmp -xz -f '-'

# ---
FROM postgres:14.1 

RUN useradd -M -c /bin/bash stolon

RUN set -ex \
  && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
  && echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen

COPY --from=builder /tmp/stolon/bin /usr/local/bin/
COPY --from=builder /tmp/wal-g-pg-ubuntu-20.04-amd64 /usr/local/bin/wal-g
COPY --from=builder /tmp/wal2json/wal2json.so /usr/lib/postgresql/14/lib/pgaudit.so /usr/lib/postgresql/14/lib/
COPY --from=builder /usr/share/postgresql/14/extension/pgaudit--1.6.1.sql /usr/share/postgresql/14/extension/pgaudit.control /usr/share/postgresql/14/extension/
COPY --from=builder /tmp/envdir /usr/local/bin/
COPY --from=builder /tmp/pgcenter /usr/local/bin/