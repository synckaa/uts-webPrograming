-- ============================================================
-- audio_shop.sql
-- Skema + data contoh untuk prototipe SoundHub
-- Target: MySQL 8.x
-- Cara pakai: mysql -u root -p < audio_shop.sql
-- ============================================================

DROP DATABASE IF EXISTS audio_shop;
CREATE DATABASE audio_shop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE audio_shop;

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1. SKEMA
-- ------------------------------------------------------------

CREATE TABLE categories (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL UNIQUE,
  slug       VARCHAR(120) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE brands (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL UNIQUE,
  slug       VARCHAR(120) NOT NULL UNIQUE,
  logo_url   VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE products (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT UNSIGNED NOT NULL,
  brand_id    BIGINT UNSIGNED NOT NULL,
  title       VARCHAR(200) NOT NULL,
  slug        VARCHAR(220) NOT NULL UNIQUE,
  description TEXT NULL,
  image_url   VARCHAR(255) NOT NULL,
  sold_count  INT UNSIGNED NOT NULL DEFAULT 0,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id),
  CONSTRAINT fk_products_brand    FOREIGN KEY (brand_id)    REFERENCES brands(id),
  INDEX idx_products_trending (is_active, sold_count, created_at),
  INDEX idx_products_title (title)
) ENGINE=InnoDB;

CREATE TABLE product_variants (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  name       VARCHAR(100) NOT NULL,
  sku        VARCHAR(50) NOT NULL UNIQUE,
  price      DECIMAL(12,2) NOT NULL,
  stock      INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_variants_product FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE CASCADE,
  UNIQUE KEY uq_variant_product_name (product_id, name),
  CONSTRAINT chk_variant_price CHECK (price >= 0)
) ENGINE=InnoDB;

CREATE TABLE users (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE carts (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    BIGINT UNSIGNED NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_carts_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE cart_items (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cart_id    BIGINT UNSIGNED NOT NULL,
  variant_id BIGINT UNSIGNED NOT NULL,
  qty        INT UNSIGNED NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_cart_variant (cart_id, variant_id),
  CONSTRAINT fk_items_cart FOREIGN KEY (cart_id)
    REFERENCES carts(id) ON DELETE CASCADE,
  CONSTRAINT fk_items_variant FOREIGN KEY (variant_id)
    REFERENCES product_variants(id),
  CONSTRAINT chk_cart_qty CHECK (qty >= 1)
) ENGINE=InnoDB;

CREATE TABLE transactions (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  invoice_no       VARCHAR(30) NOT NULL UNIQUE,
  user_id          BIGINT UNSIGNED NOT NULL,
  total_amount     DECIMAL(12,2) NOT NULL,
  status           ENUM('pending','paid','shipped','completed','cancelled')
                   NOT NULL DEFAULT 'pending',
  payment_method   VARCHAR(50) NOT NULL,
  shipping_address TEXT NOT NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_transactions_user (user_id, created_at),
  CONSTRAINT chk_transaction_total CHECK (total_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE transaction_items (
  id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  transaction_id BIGINT UNSIGNED NOT NULL,
  variant_id     BIGINT UNSIGNED NOT NULL,
  product_title  VARCHAR(200) NOT NULL,
  variant_name   VARCHAR(100) NOT NULL,
  price          DECIMAL(12,2) NOT NULL,
  qty            INT UNSIGNED NOT NULL,
  subtotal       DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_transaction_items_transaction FOREIGN KEY (transaction_id)
    REFERENCES transactions(id) ON DELETE CASCADE,
  CONSTRAINT fk_transaction_items_variant FOREIGN KEY (variant_id)
    REFERENCES product_variants(id),
  CONSTRAINT chk_transaction_item_qty CHECK (qty >= 1),
  CONSTRAINT chk_transaction_item_price CHECK (price >= 0),
  CONSTRAINT chk_transaction_item_subtotal CHECK (subtotal >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. DATA CONTOH (SEED)
-- ------------------------------------------------------------

INSERT INTO brands (id, name, slug) VALUES
  (1, 'Sony',       'sony'),
  (2, 'Sennheiser', 'sennheiser'),
  (3, 'Apple',      'apple'),
  (4, 'Samsung',    'samsung'),
  (5, 'JBL',        'jbl'),
  (6, 'Bose',       'bose'),
  (7, 'Anker',      'anker'),
  (8, 'Ugreen',     'ugreen');

INSERT INTO categories (id, name, slug) VALUES
  (1, 'Headphone',      'headphone'),
  (2, 'Earphone / TWS', 'earphone-tws'),
  (3, 'Speaker',        'speaker'),
  (4, 'Aksesoris',      'aksesoris');

-- sold_count mengikuti urutan produk trending pada prototipe UI
INSERT INTO products
  (id, category_id, brand_id, title, slug, description, image_url, sold_count, is_active)
VALUES
  (1, 1, 1, 'Sony WH-1000XM5', 'sony-wh-1000xm5',
   'Headphone over-ear dengan noise cancelling adaptif, driver 30 mm, dan baterai hingga 30 jam.',
   '/assets/sony-wh-1000xm5.webp', 1240, 1),
  (2, 2, 3, 'Apple AirPods Pro 2', 'apple-airpods-pro-2',
   'TWS dengan active noise cancellation, audio spatial, dan baterai hingga 6 jam.',
   '/assets/airpods-pro-2.webp', 1080, 1),
  (3, 3, 5, 'JBL Flip 6', 'jbl-flip-6',
   'Speaker portabel tahan air IP67 dengan driver racetrack dan baterai 12 jam.',
   '/assets/jbl-flip-6.webp', 960, 1),
  (4, 4, 8, 'Ugreen RCA Audio Cable', 'ugreen-rca-audio-cable',
   'Kabel audio RCA stereo 2RCA ke 2RCA dengan konektor berlapis emas.',
   '/assets/ugreen-rca-cable.webp', 840, 1),
  (5, 1, 2, 'Sennheiser HD 560S', 'sennheiser-hd-560s',
   'Headphone open-back untuk mixing dan mendengarkan detail, driver 38 mm.',
   '/assets/sennheiser-hd-560s.webp', 720, 1),
  (6, 2, 4, 'Samsung Galaxy Buds2 Pro', 'samsung-galaxy-buds2-pro',
   'TWS dengan audio 24-bit Hi-Fi, ANC cerdas, dan desain ergonomis.',
   '/images/products/samsung-galaxy-buds2-pro.webp', 610, 1),
  (7, 3, 6, 'Bose SoundLink Flex', 'bose-soundlink-flex',
   'Speaker Bluetooth tangguh dengan suara jernih, tahan air dan debu.',
   '/images/products/bose-soundlink-flex.webp', 540, 1),
  (8, 1, 7, 'Anker Soundcore Life Q30', 'anker-soundcore-life-q30',
   'Headphone ANC hybrid dengan baterai hingga 40 jam.',
   '/images/products/anker-soundcore-life-q30.webp', 480, 1);

INSERT INTO product_variants (product_id, name, sku, price, stock) VALUES
  (1, 'Hitam',         'SONY-XM5-BLK', 4499000, 12),
  (1, 'Perak',         'SONY-XM5-SLV', 4599000,  5),
  (1, 'Midnight Blue', 'SONY-XM5-BLU', 4699000,  7),
  (2, 'USB-C',         'APL-APP2-USBC', 3499000, 18),
  (2, 'Lightning',     'APL-APP2-LTN',  3499000,  6),
  (3, 'Hitam',         'JBL-F6-BLK',    1599000,  9),
  (3, 'Biru',          'JBL-F6-BLU',    1599000,  4),
  (4, '1 m',           'UGR-RCA-1M',      99000, 40),
  (4, '2 m',           'UGR-RCA-2M',     119000, 25),
  (4, '3 m',           'UGR-RCA-3M',     139000, 10),
  (5, 'Hitam',         'SENN-560S-BLK', 2899000,  8),
  (5, 'Hitam + Pouch', 'SENN-560S-PCH', 3199000,  4),
  (6, 'Graphite',      'SAM-GB2P-GRP',  2799000, 30),
  (6, 'Putih',         'SAM-GB2P-WHT',  2799000, 26),
  (7, 'Hitam',         'BOSE-SLF-BLK',  2699000, 20),
  (7, 'Putih',         'BOSE-SLF-WHT',  2699000, 15),
  (8, 'Hitam',         'ANK-Q30-BLK',   1099000, 45),
  (8, 'Biru',          'ANK-Q30-BLU',   1099000, 30);

-- Tabel users sengaja kosong. Akun dibuat lewat Signup dan password
-- harus di-hash dengan bcrypt oleh aplikasi, bukan disimpan sebagai teks asli.

-- ------------------------------------------------------------
-- 3. QUERY REFERENSI
-- ------------------------------------------------------------

-- 5 produk trending (Dashboard)
-- Harga memakai varian termurah, bukan kolom harga di tabel products.
SELECT p.id, p.title, p.slug, p.image_url, b.name AS brand,
       (SELECT MIN(v.price) FROM product_variants v
         WHERE v.product_id = p.id) AS price_from
FROM products p
JOIN brands b ON b.id = p.brand_id
WHERE p.is_active = 1
ORDER BY p.sold_count DESC, p.created_at DESC
LIMIT 5;

-- Pencarian berdasarkan judul produk atau nama merek
SELECT p.id, p.title, p.slug, p.image_url, b.name AS brand,
       (SELECT MIN(v.price) FROM product_variants v
         WHERE v.product_id = p.id) AS price_from
FROM products p
JOIN brands b ON b.id = p.brand_id
WHERE p.is_active = 1
  AND (p.title LIKE CONCAT('%', ?, '%')
    OR b.name LIKE CONCAT('%', ?, '%'))
ORDER BY p.sold_count DESC;

-- Detail produk beserta seluruh varian
SELECT p.id, p.title, p.slug, p.description, p.image_url,
       b.name AS brand, c.name AS category,
       v.id AS variant_id, v.name AS variant_name, v.sku, v.price, v.stock
FROM products p
JOIN brands b ON b.id = p.brand_id
JOIN categories c ON c.id = p.category_id
JOIN product_variants v ON v.product_id = p.id
WHERE p.slug = ? AND p.is_active = 1
ORDER BY v.price, v.id;

-- Isi keranjang milik pengguna
SELECT ci.id, p.title, v.name AS variant_name, v.price, ci.qty,
       (v.price * ci.qty) AS subtotal
FROM carts c
JOIN cart_items ci ON ci.cart_id = c.id
JOIN product_variants v ON v.id = ci.variant_id
JOIN products p ON p.id = v.product_id
WHERE c.user_id = ?
ORDER BY ci.created_at;

-- Riwayat transaksi milik pengguna
SELECT t.invoice_no, t.total_amount, t.status, t.payment_method,
       t.shipping_address, t.created_at
FROM transactions t
WHERE t.user_id = ?
ORDER BY t.created_at DESC;

-- Rincian item dalam satu transaksi
SELECT ti.product_title, ti.variant_name, ti.price, ti.qty, ti.subtotal
FROM transaction_items ti
JOIN transactions t ON t.id = ti.transaction_id
WHERE t.invoice_no = ?;

-- Alur checkout harus dijalankan dalam satu transaksi database:
-- START TRANSACTION;
--   INSERT INTO transactions (...) VALUES (...);
--   INSERT INTO transaction_items (...)
--     SELECT ... FROM cart_items ...;
--   UPDATE product_variants ... SET stock = stock - qty;
--   UPDATE products ... SET sold_count = sold_count + qty;
--   DELETE FROM cart_items WHERE cart_id = ?;
-- COMMIT;
