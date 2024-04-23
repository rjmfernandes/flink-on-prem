# Flink with Kafka OnPrem

## Setup

Run:

```shell
docker compose up -d 
```

Let's install some connectors:

```shell
docker compose exec connect bash
```

And then:

```shell
confluent-hub install confluentinc/kafka-connect-datagen:latest
```

And restart connect:

```shell
docker compose restart connect
```

After we can create the connectors:

```shell
curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/my-datagen-source1/config -d '{
    "name" : "my-datagen-source1",
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "kafka.topic" : "products",
    "output.data.format" : "AVRO",
    "quickstart" : "SHOES",
    "tasks.max" : "1"
}'
curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/my-datagen-source2/config -d '{
    "name" : "my-datagen-source2",
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "kafka.topic" : "customers",
    "output.data.format" : "AVRO",
    "quickstart" : "SHOE_CUSTOMERS",
    "tasks.max" : "1"
}'
curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/my-datagen-source3/config -d '{
    "name" : "my-datagen-source3",
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "kafka.topic" : "orders",
    "output.data.format" : "AVRO",
    "quickstart" : "SHOE_ORDERS",
    "tasks.max" : "1"
}'
```

Open http://localhost:9021 and check cluster is healthy including Kafka Connect.

You can also check Flink Dashboard at http://localhost:8081/.

## Flink SQL

Run:

```shell
docker-compose run sql-client
```

And execute:

```sql
CREATE TABLE products (
  `id` STRING,
  `brand` STRING,
  `name` STRING,
  `sale_price` BIGINT,
  `rating` DOUBLE,
  `$rowtime` TIMESTAMP(3) METADATA FROM 'timestamp'
) WITH (
  'connector' = 'kafka',
  'topic' = 'products',
  'properties.bootstrap.servers' = 'broker:9092',
  'properties.group.id' = 'demo3',
  'scan.startup.mode' = 'earliest-offset',
  'value.format' = 'avro-confluent',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081',
  'value.fields-include' = 'EXCEPT_KEY'
);
```

After run:

```sql
select * from products;
```

Now we can run:

```sql
CREATE TABLE customers (
  `id` STRING,
  `first_name` STRING,
  `last_name` STRING,
  `email` STRING,
  `phone` STRING,
  `street_address` STRING,
  `state` STRING,
  `zip_code` STRING,
  `country` STRING,
  `country_code` STRING,
  `$rowtime` TIMESTAMP(3) METADATA FROM 'timestamp'
) WITH (
  'connector' = 'kafka',
  'topic' = 'customers',
  'properties.bootstrap.servers' = 'broker:9092',
  'properties.group.id' = 'demo4',
  'scan.startup.mode' = 'earliest-offset',
  'value.format' = 'avro-confluent',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081',
  'value.fields-include' = 'EXCEPT_KEY'
);
```

```sql
select * from customers;
```

```sql
CREATE TABLE orders (
  `order_id` BIGINT,
  `product_id` STRING,
  `customer_id` STRING,
  `$rowtime` TIMESTAMP(3) METADATA FROM 'timestamp'
) WITH (
  'connector' = 'kafka',
  'topic' = 'orders',
  'properties.bootstrap.servers' = 'broker:9092',
  'properties.group.id' = 'demo5',
  'scan.startup.mode' = 'earliest-offset',
  'value.format' = 'avro-confluent',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081',
  'value.fields-include' = 'EXCEPT_KEY'
);
```

```sql
select * from orders;
```

### Keyed Tables

```sql
CREATE TABLE customers_keyed(
  customer_id STRING,
  first_name STRING,
  last_name STRING,
  email STRING,
  PRIMARY KEY (customer_id) NOT ENFORCED
  ) WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'customers_keyed',
  'properties.bootstrap.servers' = 'broker:9092',
  'value.format' = 'avro-confluent',
  'key.format' = 'raw',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081',
  'value.fields-include' = 'EXCEPT_KEY'
);
```

```sql
INSERT INTO customers_keyed
  SELECT id, first_name, last_name, email
    FROM customers;
```

```sql
CREATE TABLE products_keyed(
  product_id STRING,
  brand STRING,
  model STRING,
  sale_price BIGINT,
  rating DOUBLE,
  PRIMARY KEY (product_id) NOT ENFORCED
  ) WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'products_keyed',
  'properties.bootstrap.servers' = 'broker:9092',
  'value.format' = 'avro-confluent',
  'key.format' = 'raw',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081',
  'value.fields-include' = 'EXCEPT_KEY'
);
```

```sql
INSERT INTO products_keyed
  SELECT id, brand, `name`, sale_price, rating 
    FROM products;
```

### Joins, Data Enrichment

```sql
CREATE TABLE order_customer_product(
  order_id BIGINT,
  first_name STRING,
  last_name STRING,
  email STRING,
  brand STRING,
  model STRING,
  sale_price BIGINT,
  rating DOUBLE,
  PRIMARY KEY (order_id) NOT ENFORCED
)WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'order_customer_product',
  'properties.bootstrap.servers' = 'broker:9092',
  'value.format' = 'avro-confluent',
  'key.format' = 'raw',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081',
  'value.fields-include' = 'EXCEPT_KEY'
);
```

```sql
INSERT INTO order_customer_product(
  order_id,
  first_name,
  last_name,
  email,
  brand,
  model,
  sale_price,
  rating)
SELECT
  so.order_id,
  sc.first_name,
  sc.last_name,
  sc.email,
  sp.brand,
  sp.model,
  sp.sale_price,
  sp.rating
FROM 
  orders so
  INNER JOIN customers_keyed sc 
    ON so.customer_id = sc.customer_id
  INNER JOIN products_keyed sp
    ON so.product_id = sp.product_id;
```

```sql
CREATE TABLE loyalty_levels(
  email STRING,
  total BIGINT,
  rewards_level STRING,
  PRIMARY KEY (email) NOT ENFORCED
)WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'loyalty_levels',
  'properties.bootstrap.servers' = 'broker:9092',
  'value.format' = 'avro-confluent',
  'key.format' = 'raw',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081',
  'value.fields-include' = 'EXCEPT_KEY'
);
```

```sql
INSERT INTO loyalty_levels(
 email,
 total,
 rewards_level)
SELECT
  email,
  SUM(sale_price) AS total,
  CASE
    WHEN SUM(sale_price) > 80000000 THEN 'GOLD'
    WHEN SUM(sale_price) > 7000000 THEN 'SILVER'
    WHEN SUM(sale_price) > 600000 THEN 'BRONZE'
    ELSE 'CLIMBING'
  END AS rewards_level
FROM order_customer_product
GROUP BY email;
```

```sql
CREATE TABLE promotions(
  email STRING,
  promotion_name STRING,
  PRIMARY KEY (email) NOT ENFORCED
)WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'promotions',
  'properties.bootstrap.servers' = 'broker:9092',
  'value.format' = 'avro-confluent',
  'key.format' = 'raw',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081',
  'value.fields-include' = 'EXCEPT_KEY'
);
```

```sql
EXECUTE STATEMENT SET 
BEGIN

INSERT INTO promotions
SELECT
   email,
   'next_free' AS promotion_name
FROM order_customer_product
WHERE brand = 'Jones-Stokes'
GROUP BY email
HAVING COUNT(*) % 10 = 0;

INSERT INTO promotions
SELECT
     email,
     'bundle_offer' AS promotion_name
  FROM order_customer_product
  WHERE brand IN ('Braun-Bruen', 'Will Inc')
  GROUP BY email
  HAVING COUNT(DISTINCT brand) = 2 AND COUNT(brand) > 10;

END;
```

For exiting:

```
exit;
```

## Cleanup

```shell
docker compose down -v
rm -fr data
rm -fr plugins
```