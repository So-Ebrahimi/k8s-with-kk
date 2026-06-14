CREATE DATABASE IF NOT EXISTS test ON CLUSTER local_cluster;
CREATE TABLE IF NOT EXISTS test.events_replica ON CLUSTER local_cluster
(
    id UInt64,
    name String,
    created_at DateTime DEFAULT now()
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/events_replica',
    '{replica}'
)
ORDER BY id;
INSERT INTO test.events_replica (id, name)
SETTINGS async_insert = 1, wait_for_async_insert = 0
VALUES
(1, 'hello'),
(2, 'world'),
(3, 'clickhouse');
SELECT *
FROM test.events_replica;
