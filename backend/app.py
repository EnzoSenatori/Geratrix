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

# Rota de abertura de turno (US-02)
@app.route("/turno/abrir", methods=["GET", "POST"])
def turno_abrir():
    from flask import session, redirect, request
    cuidador_id = session.get("cuidador_id")
    if not cuidador_id:
        return redirect("/")

    db = get_db()
    cuidador = db.execute("SELECT * FROM cuidador WHERE id = ?", (cuidador_id,)).fetchone()

    if request.method == "POST":
        agora = HORA_DEMO or "09:40"
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO turno (cuidador_id, aberto_em) VALUES (?, ?)",
            (cuidador_id, agora)
        )
        db.commit()
        session["turno_id"] = cursor.lastrowid
        return redirect("/lista")

    # Busca o ultimo turno encerrado
    ultimo_turno = db.execute(
        """SELECT t.*, c.nome AS cuidador_nome 
           FROM turno t 
           JOIN cuidador c ON c.id = t.cuidador_id 
           WHERE t.encerrado_em IS NOT NULL 
           ORDER BY t.encerrado_em DESC LIMIT 1"""
    ).fetchone()

    alertas = []
    pendencias_lista = []
    if ultimo_turno:
        alertas = db.execute(
            """SELECT c.*, t.nome AS tipo_nome, t.unidade, r.nome AS residente_nome 
               FROM checkin c 
               JOIN item_rotina i ON i.id = c.item_id 
               JOIN tipo_checkin t ON t.id = i.tipo_id 
               JOIN residente r ON r.id = i.residente_id 
               WHERE c.turno_id = ? AND (c.fora_da_faixa = 1 OR c.status = 'nao_realizado')""",
            (ultimo_turno["id"],)
        ).fetchall()

        if ultimo_turno["pendencias"]:
            pendencias_lista = [p.strip() for p in ultimo_turno["pendencias"].split("\n") if p.strip()]

    total_residentes = db.execute("SELECT COUNT(*) AS total FROM residente").fetchone()["total"]

    return render_template(
        "abrir-turno.html",
        cuidador=cuidador,
        ultimo_turno=ultimo_turno,
        alertas=alertas,
        pendencias=pendencias_lista,
        total_residentes=total_residentes
    )

# Rota para limpar a sessão sem encerrar o turno (US-02)
@app.route("/sair")
def sair():
    from flask import session, redirect
    session.clear()
    return redirect("/")

# Consulta e calcula os itens do dia aplicados a RN-07 (US-06)
def itens_do_dia(db, data_iso, hora_atual):
    query = """
        SELECT i.id, i.horario, r.nome AS residente, t.nome AS tipo, t.natureza,
               t.unidade, t.faixa_min, t.faixa_max,
               c.status AS registro, c.fora_da_faixa, c.motivo
        FROM item_rotina i
        JOIN residente r ON r.id = i.residente_id
        JOIN tipo_checkin t ON t.id = i.tipo_id
        LEFT JOIN checkin c ON c.item_id = i.id AND date(c.registrado_em) = ?
    """
    rows = db.execute(query, (data_iso,)).fetchall()
    
    itens = []
    ordem_status = {"atrasado": 0, "pendente": 1, "feito": 2}

    for row in rows:
        item = dict(row)
        if item["registro"] is not None:
            item["status_calculado"] = "feito"
        elif item["horario"] < hora_atual:
            item["status_calculado"] = "atrasado"
        else:
            item["status_calculado"] = "pendente"
        itens.append(item)

    # Ordena por (atrasado, pendente, feito) e por horário dentro de cada grupo
    itens.sort(key=lambda x: (ordem_status[x["status_calculado"]], x["horario"]))
    return itens

# Rota principal do turno ativo: Lista do agora (US-06)
@app.route("/lista")
def lista():
    from flask import session, redirect, request
    from datetime import date

    cuidador_id = session.get("cuidador_id")
    turno_id = session.get("turno_id")

    if not cuidador_id or not turno_id:
        return redirect("/")

    db = get_db()
    cuidador = db.execute("SELECT * FROM cuidador WHERE id = ?", (cuidador_id,)).fetchone()

    hora_atual = HORA_DEMO or "09:40"
    data_hoje = date.today().isoformat()

    todos_itens = itens_do_dia(db, data_hoje, hora_atual)

    total = len(todos_itens)
    feitos = sum(1 for i in todos_itens if i["status_calculado"] == "feito")
    atrasados = sum(1 for i in todos_itens if i["status_calculado"] == "atrasado")
    progresso = int((feitos / total) * 100) if total > 0 else 0

    filtro = request.args.get("filtro")
    if filtro in ["atrasado", "pendente", "feito"]:
        itens_filtrados = [i for i in todos_itens if i["status_calculado"] == filtro]
    else:
        itens_filtrados = todos_itens

    return render_template(
        "lista.html",
        cuidador=cuidador,
        itens=itens_filtrados,
        total=total,
        feitos=feitos,
        atrasados=atrasados,
        progresso=progresso,
        filtro_atual=filtro
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)