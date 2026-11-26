import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import psycopg2

def get_conn():
    return psycopg2.connect(
        host="db",
        port=5432,
        dbname=os.getenv("POSTGRES_DB", "dormhelper_dev"),
        user=os.getenv("POSTGRES_USER", "dormhelper_user"),
        password=os.getenv("POSTGRES_PASSWORD", "changeme_db_password"),
    )

def init_db():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS materials (
                    id SERIAL PRIMARY KEY,
                    title TEXT NOT NULL,
                    subject TEXT NOT NULL,
                    material_type TEXT NOT NULL,
                    author TEXT NOT NULL
                )
            """)
        conn.commit()

class Handler(BaseHTTPRequestHandler):
    def _send_json(self, code, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/api/materials":
            with get_conn() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT id, title, subject, material_type, author FROM materials ORDER BY id DESC")
                    rows = cur.fetchall()
            items = [
                {"id": r[0], "title": r[1], "subject": r[2], "type": r[3], "author": r[4]}
                for r in rows
            ]
            self._send_json(200, items)
        else:
            self._send_json(404, {"error": "Not found"})

    def do_POST(self):
        if self.path == "/api/materials":
            length = int(self.headers.get("Content-Length", 0))
            data = json.loads(self.rfile.read(length).decode("utf-8"))
            with get_conn() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "INSERT INTO materials (title, subject, material_type, author) VALUES (%s, %s, %s, %s) RETURNING id",
                        (data["title"], data["subject"], data["type"], data["author"]),
                    )
                    new_id = cur.fetchone()[0]
                conn.commit()
            self._send_json(201, {"id": new_id, **data})
        else:
            self._send_json(404, {"error": "Not found"})

init_db()
ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()