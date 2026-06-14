# clickhouse-local

Local ClickHouse Helm chart with:

- 3 ClickHouse replicas
- 3 ClickHouse Keeper replicas
- Full ArvanCloud Docker image address:
  `docker.arvancloud.ir/clickhouse/clickhouse-server:26.3`

## Install

```bash
helm upgrade --install ch ./clickhouse-local
```

## Check rendered images

```bash
helm template ch ./clickhouse-local | grep "image:"
```

Expected:

```text
image: docker.arvancloud.ir/clickhouse/clickhouse-server:26.3
image: docker.arvancloud.ir/clickhouse/clickhouse-server:26.3
```

## Test pull with containerd

```bash
sudo crictl pull docker.arvancloud.ir/clickhouse/clickhouse-server:26.3
```

or:

```bash
sudo nerdctl -n k8s.io pull docker.arvancloud.ir/clickhouse/clickhouse-server:26.3
```

## Port forward

```bash
kubectl port-forward svc/ch-clickhouse 8123:8123
curl 'http://localhost:8123/?query=SELECT%201'
```

## Test replicated table

```bash
kubectl exec -it ch-clickhouse-0 -- clickhouse-client
```

```sql
CREATE DATABASE IF NOT EXISTS test ON CLUSTER local_cluster;

CREATE TABLE test.events ON CLUSTER local_cluster
(
    id UInt64,
    name String
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/events', '{replica}')
ORDER BY id;

INSERT INTO test.events VALUES (1, 'hello');

SELECT * FROM test.events;
```

## Uninstall

```bash
helm uninstall ch
kubectl delete pvc -l app.kubernetes.io/component=clickhouse
kubectl delete pvc -l app.kubernetes.io/component=keeper
```
