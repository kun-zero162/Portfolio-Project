-- TIỀN XỬ LÝ - PREPROCESSING

-- Bỏ đi chuỗi " UTC" trong các cột mang ý nghĩa thời gian
UPDATE inventory
SET created_at=left(created_at, LEN(created_at)-4)
WHERE created_at is not null

UPDATE inventory
SET sold_at=left(sold_at, LEN(sold_at)-4)
WHERE sold_at is not null

UPDATE orders
SET shipped_at=left(shipped_at, LEN(shipped_at)-4)
WHERE shipped_at is not null

UPDATE orders
SET delivered_at=left(delivered_at, LEN(delivered_at)-4)
WHERE delivered_at is not null

---------------------
-- Đổi các cột ngày tháng sang kiểu datetime

ALTER TABLE customers
ALTER COLUMN created_at datetime2(3);

ALTER TABLE events
ALTER COLUMN created_at datetime2(3);


ALTER TABLE inventory
ALTER COLUMN created_at datetime2(3); 
ALTER TABLE inventory
ALTER COLUMN sold_at datetime2(3);

ALTER TABLE orders
ALTER COLUMN created_at datetime2(3);
ALTER TABLE orders
ALTER COLUMN returned_at datetime2(3);
ALTER TABLE orders
ALTER COLUMN shipped_at datetime2(3);
ALTER TABLE orders
ALTER COLUMN delivered_at datetime2(3);

---------------------

-- Query thử
select top 20 * 
from orders
order by delivered_at desc