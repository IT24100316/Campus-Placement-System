import psycopg2
import os

try:
    conn = psycopg2.connect('postgresql://postgres.hyxtmbncjolcepfvongh:Sef%40project%23123@aws-0-ap-northeast-1.pooler.supabase.com:5432/postgres')
    cur = conn.cursor()
    cur.execute('SELECT "Status", COUNT(*) FROM "Applications" GROUP BY "Status";')
    rows = cur.fetchall()
    print("Applications in DB:")
    for row in rows:
        print(f"Status: {row[0]}, Count: {row[1]}")
except Exception as e:
    print(f"Error: {e}")
