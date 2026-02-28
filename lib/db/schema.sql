
CREATE TABLE IF NOT EXISTS inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price REAL, quantity INTEGER, image_url TEXT);

CREATE TABLE IF NOT EXISTS item_barcodes (id INTEGER PRIMARY KEY AUTOINCREMENT, item_id INTEGER, barcode TEXT, FOREIGN KEY(item_id) REFERENCES inventory(id));

CREATE TABLE IF NOT EXISTS sales_history (id INTEGER PRIMARY KEY AUTOINCREMENT, items_sold TEXT, transaction_type TEXT, date TEXT, amount REAL);

CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, company_name TEXT, number_of_logins INTEGER, isDarkMode INTEGER, has_seen_tutorial INTEGER DEFAULT 0);