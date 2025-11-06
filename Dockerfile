# Dockerfile

# Gunakan image resmi Airflow sebagai dasar
FROM apache/airflow:2.8.1

# Salin file requirements.txt ke dalam image
COPY requirements.txt /opt/airflow/requirements.txt

# Jalankan pip install SAAT image ini DIBANGUN
# Ini akan meng-install pandas, sqlalchemy, dll SEBELUM Airflow berjalan
RUN pip install -r /opt/airflow/requirements.txt