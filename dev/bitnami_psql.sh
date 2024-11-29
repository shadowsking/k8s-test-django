#!/bin/bash

POSTGRES_USER=${1:-test_k8s}
POSTGRES_PASSWORD=${2:-OwOtBep9Frut}
POSTGRES_DB=${3:-test_k8s}

helm repo add bitnami https://charts.bitnami.com/bitnami

helm install dev-pg bitnami/postgresql \
  --set global.postgresql.auth.postgresPassword=${POSTGRES_PASSWORD} \
  --set global.postgresql.auth.database=${POSTGRES_DB} \
  --set global.postgresql.auth.username=${POSTGRES_USER} \
  --set global.postgresql.auth.password=${POSTGRES_PASSWORD} \
  --set global.postgresql.service.ports.postgresql=5434

kubectl run dev-pg-postgresql-client --rm --tty -i --restart=Never --namespace default \
  --image docker.io/bitnami/postgresql:16.2.0-debian-12-r5 \
  --env="PGPASSWORD=${POSTGRES_PASSWORD}" \
  --command -- psql --host dev-pg-postgresql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -p 5434
