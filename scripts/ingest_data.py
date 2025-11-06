# scripts/ingest_data.py (REVISI - Perbaikan 'conn.commit')

import pandas as pd
from sqlalchemy import create_engine, text
import os
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

DB_USER = os.environ.get('POSTGRES_USER')
DB_PASSWORD = os.environ.get('POSTGRES_PASSWORD')
DB_HOST = os.environ.get('POSTGRES_HOST')
DB_PORT = os.environ.get('POSTGRES_PORT')
DB_NAME = os.environ.get('POSTGRES_DB')

DATA_PATH = '/opt/airflow/data/'
TRANSACTIONS_FILE = os.path.join(DATA_PATH, '1dfTransjakarta180kRows.csv')
HALTE_FILE = os.path.join(DATA_PATH, 'data_lokasi_halte.csv')

def ingest_data():
    try:
        logging.info(f"Connecting to database {DB_NAME} at {DB_HOST}...")
        connection_string = f'postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
        engine = create_engine(connection_string)

        # Buat schema 'staging' jika belum ada
        with engine.connect() as conn:
            conn.execute(text("CREATE SCHEMA IF NOT EXISTS staging"))
            # --- BARIS PERBAIKAN ---
            # HAPUS 'conn.commit()' DARI SINI
            # Perintah DDL (seperti CREATE SCHEMA) sudah auto-commit.
            logging.info("Schema 'staging' checked/created.")

        # 1. Ingest Data Transaksi
        logging.info(f"Reading {TRANSACTIONS_FILE}...")
        df_transactions = pd.read_csv(TRANSACTIONS_FILE)
        logging.info(f"Read {len(df_transactions)} transaction rows.")
        
        df_transactions.to_sql('stg_transactions', engine, schema='staging', if_exists='replace', index=False)
        logging.info("Successfully ingested transactions to staging.stg_transactions")

        # 2. Ingest Data Halte
        logging.info(f"Reading {HALTE_FILE}...")
        df_halte = pd.read_csv(HALTE_FILE)
        logging.info(f"Read {len(df_halte)} halte rows.")
        
        df_halte.to_sql('stg_halte', engine, schema='staging', if_exists='replace', index=False)
        logging.info("Successfully ingested halte data to staging.stg_halte")

        logging.info("\n--- INGESTION PROCESS COMPLETED SUCCESSFULLY ---")

    except Exception as e:
        logging.error(f"\n--- !!! ERROR DURING INGESTION !!! ---")
        logging.error(f"Error: {e}")
        raise

if __name__ == "__main__":
    ingest_data()