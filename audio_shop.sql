-- ============================================================
-- audio_shop.sql
-- Skema + data contoh untuk prototipe Toko Online Produk Audio
-- Target: MySQL 8.x
-- Cara pakai:  mysql -u root -p < audio_shop.sql
-- ============================================================

DROP DATABASE IF EXISTS audio_shop;
CREATE DATABASE audio_shop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE audio_shop;

-- ------------------------------------------------------------
-- 1. SKEMA
-- ------------------------------------------------------------

CREATE TABLE users (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE brands (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL UNIQUE,
  slug       VARCHAR(120) NOT NULL UNIQUE,
  logo_url   VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL UNIQUE,
  slug       VARCHAR(120) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  brand_id    INT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  name        VARCHAR(200) NOT NULL,
  slug        VARCHAR(220) NOT NULL UNIQUE,
  description TEXT NULL,
  base_price  DECIMAL(12,2) NOT NULL,           -- harga mulai dari (IDR)
  sold_count  INT UNSIGNED NOT NULL DEFAULT 0,  -- dasar penentuan trending
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_brand    FOREIGN KEY (brand_id)    REFERENCES brands(id),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id),
  INDEX idx_products_sold (sold_count),
  INDEX idx_products_name (name)
);

CREATE TABLE product_variants (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  sku        VARCHAR(60) NOT NULL UNIQUE,
  name       VARCHAR(100) NOT NULL,             -- contoh: Hitam, Putih, Biru
  price      DECIMAL(12,2) NOT NULL,
  stock      INT UNSIGNED NOT NULL DEFAULT 0,
  CONSTRAINT fk_variants_product FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE product_images (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  image_url  VARCHAR(255) NOT NULL,
  is_primary TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_images_product FOREIGN KEY (product_id)
    REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE carts (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    BIGINT UNSIGNED NOT NULL UNIQUE,   -- satu user, satu keranjang
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_carts_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE cart_items (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cart_id    BIGINT UNSIGNED NOT NULL,
  variant_id BIGINT UNSIGNED NOT NULL,
  qty        INT UNSIGNED NOT NULL DEFAULT 1,
  added_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_cart_variant (cart_id, variant_id),  -- cegah baris ganda
  CONSTRAINT fk_items_cart    FOREIGN KEY (cart_id)    REFERENCES carts(id) ON DELETE CASCADE,
  CONSTRAINT fk_items_variant FOREIGN KEY (variant_id) REFERENCES product_variants(id)
);

-- Opsional: agar logout benar-benar mencabut JWT
CREATE TABLE revoked_tokens (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  token_jti  VARCHAR(64) NOT NULL UNIQUE,
  user_id    BIGINT UNSIGNED NOT NULL,
  expires_at DATETIME NOT NULL,
  CONSTRAINT fk_revoked_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

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
  (1, 'Headphone',       'headphone'),
  (2, 'Earphone / TWS',  'earphone-tws'),
  (3, 'Speaker',         'speaker'),
  (4, 'Aksesoris',       'aksesoris');

-- sold_count sengaja dibuat bervariasi agar 5 trending terlihat jelas
INSERT INTO products (id, brand_id, category_id, name, slug, description, base_price, sold_count) VALUES
  (1,  1, 1, 'Sony WH-1000XM5', 'sony-wh-1000xm5',
       'Headphone nirkabel dengan noise cancelling terbaik di kelasnya, baterai hingga 30 jam, dan suara jernih untuk musik maupun panggilan.',
       5499000, 980),
  (2,  2, 1, 'Sennheiser HD 560S', 'sennheiser-hd-560s',
       'Headphone open-back berkabel dengan suara natural dan luas, cocok untuk pendengar audiophile di rumah.',
       1999000, 240),
  (3,  3, 2, 'Apple AirPods Pro', 'apple-airpods-pro',
       'Earbuds nirkabel dengan Active Noise Cancellation, mode Transparency, dan casing pengisian MagSafe.',
       3999000, 1250),
  (4,  4, 2, 'Samsung Galaxy Buds2 Pro', 'samsung-galaxy-buds2-pro',
       'TWS dengan audio 24-bit Hi-Fi, ANC cerdas, dan desain ergonomis yang nyaman dipakai lama.',
       2799000, 760),
  (5,  5, 3, 'JBL Flip 6', 'jbl-flip-6',
       'Speaker Bluetooth portabel tahan air dan debu IP67 dengan bass bertenaga dan baterai hingga 12 jam.',
       1799000, 1420),
  (6,  6, 3, 'Bose SoundLink Flex', 'bose-soundlink-flex',
       'Speaker Bluetooth tangguh dengan suara jernih dan postur seimbang, tahan air dan debu.',
       2699000, 540),
  (7,  7, 1, 'Anker Soundcore Life Q30', 'anker-soundcore-life-q30',
       'Headphone ANC hybrid dengan baterai hingga 40 jam dengan harga yang bersahabat.',
       1099000, 890),
  (8,  8, 4, 'Ugreen DAC Mini USB-C', 'ugreen-dac-mini-usb-c',
       'Adaptor DAC USB-C ke jack 3.5mm untuk meningkatkan kualitas suara dari ponsel atau laptop.',
       199000, 310),
  (9,  5, 2, 'JBL Tune 230NC TWS', 'jbl-tune-230nc-tws',
       'Earbuds nirkabel dengan ANC, JBL Pure Bass Sound, dan total baterai hingga 40 jam dengan casing.',
       1299000, 1100),
  (10, 1, 2, 'Sony WF-1000XM5', 'sony-wf-1000xm5',
       'TWS premium dengan noise cancelling unggulan dan ukuran yang lebih kecil dan nyaman.',
       3999000, 670),
  (11, 7, 3, 'Anker Soundcore Motion+', 'anker-soundcore-motion-plus',
       'Speaker Bluetooth dengan audio Hi-Res 30W dan baterai hingga 12 jam.',
       1599000, 420),
  (12, 8, 4, 'Ugreen Kabel Audio 3.5mm', 'ugreen-kabel-audio-3-5mm',
       'Kabel audio AUX 3.5mm berlapis nilon, kuat dan minim gangguan sinyal.',
       79000, 200);

INSERT INTO product_variants (product_id, sku, name, price, stock) VALUES
  (1,  'SONY-XM5-BLK',  'Hitam',        5499000, 25),
  (1,  'SONY-XM5-SLV',  'Silver',       5499000, 18),
  (1,  'SONY-XM5-BLU',  'Biru Midnight',5699000, 10),
  (2,  'SENN-560S-BLK', 'Hitam',        1999000, 12),
  (3,  'APL-APP-WHT',   'Putih',        3999000, 40),
  (3,  'APL-APP-WHT-C', 'Putih + Casing USB-C', 4299000, 22),
  (4,  'SAM-GB2P-GRP',  'Graphite',     2799000, 30),
  (4,  'SAM-GB2P-WHT',  'Putih',        2799000, 26),
  (4,  'SAM-GB2P-VLT',  'Bora Purple',  2899000, 14),
  (5,  'JBL-F6-BLK',    'Hitam',        1799000, 50),
  (5,  'JBL-F6-RED',    'Merah',        1799000, 35),
  (5,  'JBL-F6-BLU',    'Biru',         1799000, 28),
  (6,  'BOSE-SLF-BLK',  'Hitam',        2699000, 20),
  (6,  'BOSE-SLF-WHT',  'Putih',        2699000, 15),
  (7,  'ANK-Q30-BLK',   'Hitam',        1099000, 45),
  (7,  'ANK-Q30-BLU',   'Biru',         1099000, 30),
  (7,  'ANK-Q30-PNK',   'Pink',         1149000, 12),
  (8,  'UGR-DAC-BLK',   'Hitam',         199000, 80),
  (8,  'UGR-DAC-SLV',   'Silver',        199000, 60),
  (9,  'JBL-T230-BLK',  'Hitam',        1299000, 55),
  (9,  'JBL-T230-WHT',  'Putih',        1299000, 40),
  (9,  'JBL-T230-BLU',  'Biru',         1299000, 25),
  (10, 'SONY-WF5-BLK',  'Hitam',        3999000, 20),
  (10, 'SONY-WF5-SLV',  'Silver',       3999000, 16),
  (11, 'ANK-MOT-BLK',   'Hitam',        1599000, 22),
  (11, 'ANK-MOT-GRY',   'Abu-abu',      1599000, 18),
  (12, 'UGR-AUX-1M',    '1 meter',        79000, 120),
  (12, 'UGR-AUX-2M',    '2 meter',        99000, 90);

-- URL gambar bersifat placeholder; ganti dengan path gambar sebenarnya
INSERT INTO product_images (product_id, image_url, is_primary, sort_order) VALUES
  (1,  '/images/products/sony-wh-1000xm5-1.jpg',        1, 0),
  (1,  '/images/products/sony-wh-1000xm5-2.jpg',        0, 1),
  (2,  '/images/products/sennheiser-hd-560s-1.jpg',     1, 0),
  (3,  '/images/products/apple-airpods-pro-1.jpg',      1, 0),
  (3,  '/images/products/apple-airpods-pro-2.jpg',      0, 1),
  (4,  '/images/products/galaxy-buds2-pro-1.jpg',       1, 0),
  (5,  '/images/products/jbl-flip-6-1.jpg',             1, 0),
  (5,  '/images/products/jbl-flip-6-2.jpg',             0, 1),
  (6,  '/images/products/bose-soundlink-flex-1.jpg',    1, 0),
  (7,  '/images/products/anker-q30-1.jpg',              1, 0),
  (8,  '/images/products/ugreen-dac-mini-1.jpg',        1, 0),
  (9,  '/images/products/jbl-tune-230nc-1.jpg',         1, 0),
  (10, '/images/products/sony-wf-1000xm5-1.jpg',        1, 0),
  (11, '/images/products/anker-motion-plus-1.jpg',      1, 0),
  (12, '/images/products/ugreen-aux-cable-1.jpg',       1, 0);

-- Catatan: tabel users dikosongkan. Akun dibuat lewat fitur Signup
-- (password harus di-hash dengan bcrypt oleh aplikasi, bukan disimpan polos).

-- ------------------------------------------------------------
-- 3. QUERY REFERENSI
-- ------------------------------------------------------------

-- 5 produk trending (Home)
-- SELECT p.id, p.name, p.slug, p.base_price, b.name AS brand,
--        (SELECT image_url FROM product_images
--          WHERE product_id = p.id AND is_primary = 1 LIMIT 1) AS image
-- FROM products p
-- JOIN brands b ON b.id = p.brand_id
-- WHERE p.is_active = 1
-- ORDER BY p.sold_count DESC
-- LIMIT 5;
