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

# Rota de login por PIN do cuidador
@app.route("/pin/<int:id>", methods=["GET", "POST"])
def pin(id):
    from flask import session, redirect, request
    db = get_db()
    cuidador = db.execute("SELECT * FROM cuidador WHERE id = ? AND ativo = 1", (id,)).fetchone()
    
    if not cuidador:
        return redirect("/")

    if request.method == "GET" or session.get("pin_de") != id:
        session["pin"] = ""
        session["pin_de"] = id

    erro = None
    pin_atual = session.get("pin", "")

    if request.method == "POST":
        tecla = request.form.get("tecla")
        
        if tecla in [str(i) for i in range(10)]:
            if len(pin_atual) < 4:
                pin_atual += tecla
        elif tecla == "apagar":
            pin_atual = pin_atual[:-1]
        elif tecla == "entrar":
            if pin_atual == cuidador["pin"]:
                session.clear()
                session["cuidador_id"] = id
                
                # Verifica se o cuidador já tem um turno aberto
                turno_aberto = db.execute(
                    "SELECT id FROM turno WHERE cuidador_id = ? AND encerrado_em IS NULL",
                    (id,)
                ).fetchone()
                
                if turno_aberto:
                    session["turno_id"] = turno_aberto["id"]
                    return redirect("/lista")
                else:
                    return redirect("/turno/abrir")
            else:
                erro = "PIN incorreto. Tente novamente."
                pin_atual = ""

        session["pin"] = pin_atual

    return render_template(
        "pin.html",
        cuidador=cuidador,
        preenchidos=len(pin_atual),
        erro=erro
    )

    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)