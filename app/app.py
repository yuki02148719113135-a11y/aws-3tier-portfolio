import pymysql
from flask import Flask, redirect, render_template, request, url_for
from config import DB_HOST, DB_NAME, DB_PASS, DB_PORT, DB_USER

app = Flask(__name__)


def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        port=DB_PORT,
        cursorclass=pymysql.cursors.DictCursor,
    )


def init_db():
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS todos (
                id INT AUTO_INCREMENT PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                done BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
    conn.commit()
    conn.close()


@app.route("/")
def index():
    try:
        conn = get_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM todos ORDER BY created_at DESC")
            todos = cursor.fetchall()
        conn.close()
    except Exception:
        todos = []
    return render_template("index.html", todos=todos)


@app.route("/add", methods=["POST"])
def add():
    title = request.form.get("title", "").strip()
    if title:
        conn = get_connection()
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO todos (title) VALUES (%s)", (title,))
        conn.commit()
        conn.close()
    return redirect(url_for("index"))


@app.route("/done/<int:todo_id>", methods=["POST"])
def done(todo_id):
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute("UPDATE todos SET done = NOT done WHERE id = %s", (todo_id,))
    conn.commit()
    conn.close()
    return redirect(url_for("index"))


@app.route("/delete/<int:todo_id>", methods=["POST"])
def delete(todo_id):
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute("DELETE FROM todos WHERE id = %s", (todo_id,))
    conn.commit()
    conn.close()
    return redirect(url_for("index"))


if __name__ == "__main__":
    try:
        init_db()
    except Exception as e:
        print(f"[WARNING] DB init skipped: {e}")
    app.run(host="0.0.0.0", port=5000, debug=False)
