ALTER TABLE product
    ADD price DOUBLE PRECISION,
    ADD PRIMARY KEY (id);

ALTER TABLE orders
    ADD date_created DATE,
    ADD PRIMARY KEY (id);

DROP TABLE product_info;
DROP TABLE orders_date;

ALTER TABLE order_product
    ADD CONSTRAINT fk_product_id FOREIGN KEY (product_id) REFERENCES product (id),
    ADD CONSTRAINT fk_orders_id FOREIGN KEY (order_id) REFERENCES orders (id);