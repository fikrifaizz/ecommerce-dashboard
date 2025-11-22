import pandas as pd
import sqlite3
from pathlib import Path
import time
import os

# Paths
RAW_DATA = Path('data/raw')
DB_DIR = Path('data/database')
if not DB_DIR.exists():
    DB_DIR.mkdir(parents=True, exist_ok=True)
DB_PATH = DB_DIR / 'ecommerce.db'

# Create database connection
conn = sqlite3.connect(DB_PATH)
print(f"Database created at: {DB_PATH}\n")

# Complete list of tables
csv_files = {
    'orders': 'olist_orders_dataset.csv',
    'order_items': 'olist_order_items_dataset.csv',
    'products': 'olist_products_dataset.csv',
    'customers': 'olist_customers_dataset.csv',
    'payments': 'olist_order_payments_dataset.csv',
    'reviews': 'olist_order_reviews_dataset.csv',
    'sellers': 'olist_sellers_dataset.csv',
    'product_categories': 'product_category_name_translation.csv',
    'geolocation': 'olist_geolocation_dataset.csv'  # ← ADDED!
}

print("LOADING TABLES INTO SQLITE")

# Track total time
start_time = time.time()

# Load each CSV into SQLite
for table_name, csv_file in csv_files.items():
    print(f"\nLoading {table_name}...", end=" ")
    table_start = time.time()
    
    # Read CSV
    df = pd.read_csv(RAW_DATA / csv_file)
    
    # Load to SQLite
    df.to_sql(table_name, conn, if_exists='replace', index=False)
    
    elapsed = time.time() - table_start
    print(f"{len(df):,} rows in {elapsed:.2f}s")

print("DATABASE SUMMARY")

# Verify all tables and get row counts
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = cursor.fetchall()

total_rows = 0
for table in sorted(tables):
    cursor.execute(f"SELECT COUNT(*) FROM {table[0]}")
    count = cursor.fetchone()[0]
    total_rows += count
    print(f"  {table[0]:25} : {count:>10,} rows")

print(f"  {'TOTAL':25} : {total_rows:>10,} rows")

total_time = time.time() - start_time
print(f"\nDatabase setup complete in {total_time:.2f}s!")

# Get database file size
db_size_mb = DB_PATH.stat().st_size / (1024**2)
print(f"Database size: {db_size_mb:.2f} MB")

conn.close()