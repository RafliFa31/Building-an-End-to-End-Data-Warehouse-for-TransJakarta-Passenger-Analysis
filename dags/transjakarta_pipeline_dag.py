# dags/transjakarta_pipeline_dag.py
# VERSI ARSITEKTUR ELT (FINAL)

from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.operators.bash import BashOperator
from datetime import datetime

POSTGRES_CONN_ID = "postgres_main"
TEMPLATE_SEARCH_PATH = "/opt/airflow/scripts" # Diperlukan agar Airflow menemukan file .sql

with DAG(
    dag_id="transjakarta_elt_pipeline",
    start_date=datetime(2025, 10, 28),
    schedule_interval=None,
    catchup=False,
    tags=['transjakarta', 'elt', 'project'],
    template_searchpath=TEMPLATE_SEARCH_PATH # Menambahkan path untuk mencari .sql
) as dag:

    task_start = BashOperator(
        task_id="start",
        bash_command="echo 'Memulai Transjakarta ELT Pipeline...'"
    )

    # Task 2: Python Script (E & L)
    task_ingest_data = BashOperator(
        task_id="ingest_data_to_staging",
        bash_command="python /opt/airflow/scripts/ingest_data.py",
        env={
            "POSTGRES_USER": "{{ conn.postgres_main.login }}",
            "POSTGRES_PASSWORD": "{{ conn.postgres_main.password }}",
            "POSTGRES_HOST": "{{ conn.postgres_main.host }}",
            "POSTGRES_PORT": "{{ conn.postgres_main.port }}",
            "POSTGRES_DB": "{{ conn.postgres_main.schema }}",
        },
    )

    # Task 3: SQL Script (T)
    task_transform_data = PostgresOperator(
        task_id="transform_data_in_dwh",
        postgres_conn_id=POSTGRES_CONN_ID,
        sql="transform_data.sql" # Airflow sekarang bisa menemukan file ini
    )

    task_end = BashOperator(
        task_id="end",
        bash_command="echo 'Transjakarta ELT Pipeline selesai.'"
    )

    # Mengatur urutan task: E/L >> T
    task_start >> task_ingest_data >> task_transform_data >> task_end