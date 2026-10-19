import sqlite3
from pathlib import Path
from flask import Flask, render_template, g

PASTA = Path(__file__).parent
BANCO = PASTA / "geratrix.db"

app = Flask(__name__, static_folder="css", static_url_path="/css")
app.secret_key = "geratrix-mvp-v0"

# Cria o banco de dados se ele não existir
if not BANCO.exists():
    from seed import semear
    semear()

# Relógio virtual para a demonstração
HORA_DEMO = "09:40"

# Obter a conexão com o banco de dados por requisição
def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(BANCO)
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON")
    return g.db

# Fechar a conexão com o banco de dados no fim da requisição
@app.teardown_appcontext
def fechar_db(exception):
    db = g.pop("db", None)
    if db is not None:
        db.close()

# Filtro Jinja para formatar números sem decimais desnecessários
@app.template_filter("numero")
def numero_filter(valor):
    if valor is None:
        return ""
    if float(valor).is_integer():
        return f"{int(valor)}"
    return f"{valor}".replace(".", ",")

# Rota principal que lista os cuidadores ativos
@app.route("/")
def index():
    db = get_db()
    cuidadores = db.execute("SELECT * FROM cuidador WHERE ativo = 1").fetchall()
    return render_template("index.html", cuidadores=cuidadores)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)