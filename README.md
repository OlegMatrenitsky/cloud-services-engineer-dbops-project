## Создание базы данных new_store
```sql
CREATE DATABASE new_store;
```

## Создание пользователя и выдача прав
```sql
CREATE USER new_store_user WITH PASSWORD 'ForlN8k3U_Enf83';
GRANT ALL PRIVILEGES ON DATABASE new_store TO new_store_user;
```
## Подключаемся к базе new_store и выдаём пользователю права
```sql
GRANT ALL ON SCHEMA public TO new_store_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO new_store_user;
ALTER DEFAULT PRIVILEGES FOR USER new_store_user IN SCHEMA public
GRANT ALL PRIVILEGES ON TABLES TO new_store_user;
```

## Отчет по продажам за предыдущую неделю с группировкой по дням

```sql
SELECT o.date_created, SUM(op.quantity) AS total_sausages
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped' AND o.date_created > now() - INTERVAL '7 DAY'
GROUP BY o.date_created;
```
## Время выполнения запроса без оптимизации запроса

![image](hhttps://github.com/OlegMatrenitsky/cloud-services-engineer-dbops-project/blob/main/no-index.png)

```sql
new_store=> EXPLAIN (ANALYZE)
SELECT
    o.date_created,
    SUM(op.quantity) as total_sausages_sold
FROM orders o
JOIN order_product op ON o.id = op.order_id
WHERE
    o.status = 'shipped'
    AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created
ORDER BY o.date_created;
                                                                           QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=27510.84..27533.90 rows=91 width=12) (actual time=326.889..333.098 rows=7 loops=1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=27510.84..27532.08 rows=182 width=12) (actual time=326.878..333.083 rows=21 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=26510.82..26511.05 rows=91 width=12) (actual time=319.924..319.929 rows=7 loops=3)
               Sort Key: o.date_created
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=26506.95..26507.86 rows=91 width=12) (actual time=319.219..319.225 rows=7 loops=3)
                     Group Key: o.date_created
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=14827.05..26457.46 rows=9897 width=8) (actual time=156.582..315.839 rows=7928 loops=3)
                           Hash Cond: (op.order_id = o.id)
                           ->  Parallel Seq Scan on order_product op  (cost=0.00..10536.67 rows=416667 width=12) (actual time=0.009..58.453 rows=333333 loops=3)
                           ->  Parallel Hash  (cost=14703.33..14703.33 rows=9897 width=12) (actual time=155.356..155.357 rows=7928 loops=3)
                                 Buckets: 32768  Batches: 1  Memory Usage: 1408kB
                                 ->  Parallel Seq Scan on orders o  (cost=0.00..14703.33 rows=9897 width=12) (actual time=0.035..149.145 rows=7928 loops=3)
                                       Filter: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                       Rows Removed by Filter: 325405
 Planning Time: 0.975 ms
 Execution Time: 333.257 ms
(25 rows)
```

## Время выполнения запроса после создания индекса

![image](hhttps://github.com/OlegMatrenitsky/cloud-services-engineer-dbops-project/blob/main/index.png)

## И план запроса после создания индекса

```sql

new_store=> EXPLAIN (ANALYZE)
SELECT
    o.date_created,
    SUM(op.quantity) as total_sausages_sold
FROM orders o
JOIN order_product op ON o.id = op.order_id
WHERE
    o.status = 'shipped'
    AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created
ORDER BY o.date_created;
                                                                                 QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=19703.35..19726.40 rows=91 width=12) (actual time=124.878..128.458 rows=7 loops=1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=19703.35..19724.58 rows=182 width=12) (actual time=124.870..128.446 rows=21 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=18703.33..18703.55 rows=91 width=12) (actual time=119.698..119.702 rows=7 loops=3)
               Sort Key: o.date_created
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=18699.45..18700.36 rows=91 width=12) (actual time=119.667..119.672 rows=7 loops=3)
                     Group Key: o.date_created
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=7019.55..18649.97 rows=9897 width=8) (actual time=15.929..117.260 rows=7928 loops=3)
                           Hash Cond: (op.order_id = o.id)
                           ->  Parallel Seq Scan on order_product op  (cost=0.00..10536.67 rows=416667 width=12) (actual time=0.008..33.273 rows=333333 loops=3)
                           ->  Parallel Hash  (cost=6895.84..6895.84 rows=9897 width=12) (actual time=15.114..15.115 rows=7928 loops=3)
                                 Buckets: 32768  Batches: 1  Memory Usage: 1408kB
                                 ->  Parallel Bitmap Heap Scan on orders o  (cost=327.90..6895.84 rows=9897 width=12) (actual time=1.098..13.330 rows=7928 loops=3)
                                       Recheck Cond: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                       Heap Blocks: exact=2474
                                       ->  Bitmap Index Scan on idx_orders_status_date  (cost=0.00..321.96 rows=23753 width=0) (actual time=2.246..2.246 rows=23785 loops=1)
                                             Index Cond: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
 Planning Time: 0.942 ms
 Execution Time: 128.640 ms
(27 rows)
```

Индекс на orders используется - Bitmap Index Scan on idx_orders_status_date, второй индекс использован не был. Запрос стал выполняться в 3-4 раза быстрее.