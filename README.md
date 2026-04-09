## Создание базы данных new_store
```sql
CREATE DATABASE new_store;
```

## Создание пользователя и выдача прав
```sql
CREATE USER new_store_user WITH PASSWORD 'ForlN8k3U_Enf83';
GRANT ALL PRIVILEGES ON DATABASE new_store TO new_store_user;
```
## Подключаемся к базе new_store
```sql
GRANT ALL ON SCHEMA public TO new_store_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO new_store_user;
ALTER DEFAULT PRIVILEGES FOR USER new_store_user IN SCHEMA public
GRANT ALL PRIVILEGES ON TABLES TO new_store_user;
```

## Daily Shipped Orders for the Last 7 Days
After connection to store DB, query to show the number of sausages sold each day in the past week.
```sql
SELECT o.date_created, SUM(op.quantity) AS total_sausages
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped' AND o.date_created > now() - INTERVAL '7 DAY'
GROUP BY o.date_created;
```

![image](https://github.com/AlexeyKuzko/cloud-services-engineer-dbops-project-main/blob/main/success.png)