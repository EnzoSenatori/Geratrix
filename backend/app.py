import os
import secrets
import sqlite3
from pathlib import Path
from flask import Flask, render_template, g
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash

PASTA = Path(__file__).parent
BANCO = PASTA / "geratrix.db"

app = Flask(__name__, static_folder="css", static_url_path="/css")
# OWASP A01: a chave que assina a sessão vem do ambiente (Azure), nunca do código
app.secret_key = os.environ.get("SECRET_KEY") or secrets.token_hex(32)

# Cookie de sessão fora do alcance de scripts e de outros sites; expira após 15 min sem uso
app.config.update(
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
    PERMANENT_SESSION_LIFETIME=15 * 60,  # 15 minutos, em segundos
)

# Cria o banco de dados se ele não existir
if not BANCO.exists():
    from seed import semear
    semear()

# OWASP A07: limite de tentativas erradas de PIN e tempo de bloqueio
MAX_TENTATIVAS = 5
MINUTOS_BLOQUEIO = 5

# Prepara o banco para a A07: cria a tabela de tentativas e troca PINs em texto puro por hash
def proteger_pins():
    conexao = sqlite3.connect(BANCO)
    conexao.execute("""
        CREATE TABLE IF NOT EXISTS tentativa_pin (
            cuidador_id INTEGER PRIMARY KEY REFERENCES cuidador(id),
            falhas INTEGER NOT NULL DEFAULT 0,
            bloqueado_ate TEXT
        )
    """)
    for cuidador_id, pin in conexao.execute("SELECT id, pin FROM cuidador").fetchall():
        if not pin.startswith(("scrypt:", "pbkdf2:")):
            conexao.execute("UPDATE cuidador SET pin = ? WHERE id = ?", (generate_password_hash(pin), cuidador_id))
    conexao.commit()
    conexao.close()

proteger_pins()

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

# Marca toda sessão como temporária: cada acesso renova os 15 minutos de validade
@app.before_request
def sessao_com_validade():
    from flask import session
    session.permanent = True

# Rota principal que lista os cuidadores ativos
@app.route("/")
def index():
    db = get_db()
    cuidadores = db.execute("SELECT * FROM cuidador WHERE ativo = 1").fetchall()
    return render_template("index.html", cuidadores=cuidadores)

# Devolve quantos minutos faltam para acabar o bloqueio do cuidador (0 = não está bloqueado)
def minutos_de_bloqueio(db, cuidador_id):
    linha = db.execute("SELECT bloqueado_ate FROM tentativa_pin WHERE cuidador_id = ?", (cuidador_id,)).fetchone()
    if not linha or not linha["bloqueado_ate"]:
        return 0
    restante = datetime.fromisoformat(linha["bloqueado_ate"]) - datetime.now()
    if restante.total_seconds() <= 0:
        return 0
    return int(restante.total_seconds() // 60) + 1

# Soma uma tentativa errada; na quinta seguida, bloqueia o cuidador. Devolve quantas tentativas ainda restam
def registrar_falha(db, cuidador_id):
    db.execute("INSERT OR IGNORE INTO tentativa_pin (cuidador_id) VALUES (?)", (cuidador_id,))
    db.execute("UPDATE tentativa_pin SET falhas = falhas + 1 WHERE cuidador_id = ?", (cuidador_id,))
    falhas = db.execute("SELECT falhas FROM tentativa_pin WHERE cuidador_id = ?", (cuidador_id,)).fetchone()["falhas"]
    if falhas >= MAX_TENTATIVAS:
        fim = (datetime.now() + timedelta(minutes=MINUTOS_BLOQUEIO)).strftime("%Y-%m-%d %H:%M:%S")
        db.execute("UPDATE tentativa_pin SET falhas = 0, bloqueado_ate = ? WHERE cuidador_id = ?", (fim, cuidador_id))
        db.commit()
        return 0
    db.commit()
    return MAX_TENTATIVAS - falhas

# Zera as tentativas erradas do cuidador depois de um login certo
def zerar_tentativas(db, cuidador_id):
    db.execute("UPDATE tentativa_pin SET falhas = 0, bloqueado_ate = NULL WHERE cuidador_id = ?", (cuidador_id,))
    db.commit()

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
            bloqueio = minutos_de_bloqueio(db, id)
            if bloqueio > 0:
                erro = f"Acesso bloqueado por excesso de tentativas. Tente novamente em {bloqueio} min."
                pin_atual = ""
            elif check_password_hash(cuidador["pin"], pin_atual):
                zerar_tentativas(db, id)
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
                restantes = registrar_falha(db, id)
                if restantes == 0:
                    erro = f"PIN incorreto. Acesso bloqueado por {MINUTOS_BLOQUEIO} minutos."
                else:
                    erro = f"PIN incorreto. Restam {restantes} tentativa(s)."
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
        SELECT i.id, i.horario, i.residente_id, r.nome AS residente, t.nome AS tipo, t.natureza,
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

# Salva um novo check-in imutavel no banco de dados (RN-01, RN-02)
def salvar_checkin(db, item_id, turno_id, cuidador_id, status, valor=None, fora=0, motivo=None, observacao=""):
    from datetime import datetime
    agora_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    cursor = db.cursor()
    cursor.execute(
        """INSERT INTO checkin (item_id, turno_id, cuidador_id, status, valor, fora_da_faixa, motivo, observacao, registrado_em)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (item_id, turno_id, cuidador_id, status, valor, fora, motivo, observacao, agora_str)
    )
    db.commit()

# Rota de check-in para tarefas e redirecionador para medições (US-07)
@app.route("/checkin/<int:item_id>", methods=["GET", "POST"])
def checkin_item(item_id):
    from flask import session, redirect, request, render_template
    from datetime import date

    cuidador_id = session.get("cuidador_id")
    turno_id = session.get("turno_id")

    if not cuidador_id or not turno_id:
        return redirect("/")

    db = get_db()
    data_hoje = date.today().isoformat()

    item = db.execute(
        """SELECT i.*, r.nome AS residente, t.nome AS tipo, t.natureza, t.unidade, t.faixa_min, t.faixa_max
           FROM item_rotina i
           JOIN residente r ON r.id = i.residente_id
           JOIN tipo_checkin t ON t.id = i.tipo_id
           WHERE i.id = ?""",
        (item_id,)
    ).fetchone()

    if not item:
        return redirect("/lista")

    # Verifica se já tem registro hoje (RN-03)
    ja_feito = db.execute(
        "SELECT id FROM checkin WHERE item_id = ? AND date(registrado_em) = ?",
        (item_id, data_hoje)
    ).fetchone()

    if ja_feito:
        return redirect("/lista")

    # Se for medição, encaminha para a rota específica (Passo 8)
    if item["natureza"] == "medicao":
        return redirect(f"/checkin/{item_id}/medicao")

    if request.method == "POST":
        observacao = request.form.get("observacao", "")
        salvar_checkin(db, item_id, turno_id, cuidador_id, "realizado", observacao=observacao)
        return redirect("/lista")

    hora_atual = HORA_DEMO or "09:40"
    status_item = "Atrasado" if item["horario"] < hora_atual else "Pendente"

    return render_template(
        "checkin-tarefa.html",
        item=item,
        status_item=status_item
    )

# Rota para registro de item não realizado (US-11)
@app.route("/checkin/<int:item_id>/nao-realizado", methods=["GET", "POST"])
def checkin_nao_realizado(item_id):
    from flask import session, redirect, request, render_template
    from datetime import date

    cuidador_id = session.get("cuidador_id")
    turno_id = session.get("turno_id")

    if not cuidador_id or not turno_id:
        return redirect("/")

    db = get_db()
    data_hoje = date.today().isoformat()

    item = db.execute(
        """SELECT i.*, r.nome AS residente, t.nome AS tipo, t.natureza
           FROM item_rotina i
           JOIN residente r ON r.id = i.residente_id
           JOIN tipo_checkin t ON t.id = i.tipo_id
           WHERE i.id = ?""",
        (item_id,)
    ).fetchone()

    if not item:
        return redirect("/lista")

    # Impede novo registro se já foi feito hoje (RN-03)
    ja_feito = db.execute(
        "SELECT id FROM checkin WHERE item_id = ? AND date(registrado_em) = ?",
        (item_id, data_hoje)
    ).fetchone()

    if ja_feito:
        return redirect("/lista")

    motivos = {
        "recusa": "Recusa do residente",
        "dormindo": "Residente dormindo",
        "material-indisponivel": "Material indisponível",
        "emergencia": "Emergência"
    }

    erro = None
    if request.method == "POST":
        motivo_selecionado = request.form.get("motivo")
        observacao = request.form.get("observacao", "")

        # Exige motivo válido (RN-04)
        if not motivo_selecionado or motivo_selecionado not in motivos:
            erro = "Escolha um motivo."
        else:
            salvar_checkin(
                db, item_id, turno_id, cuidador_id,
                status="nao_realizado",
                motivo=motivos[motivo_selecionado],
                observacao=observacao
            )
            return redirect("/lista")

    hora_atual = HORA_DEMO or "09:40"
    status_item = "Atrasado" if item["horario"] < hora_atual else "Pendente"

    return render_template(
        "nao-realizado.html",
        item=item,
        status_item=status_item,
        motivos=motivos,
        erro=erro
    )

# Rota para registro de medicao com alerta em duas etapas (US-09, US-13)
@app.route("/checkin/<int:item_id>/medicao", methods=["GET", "POST"])
def checkin_medicao(item_id):
    from flask import session, redirect, request, render_template
    from datetime import date

    cuidador_id = session.get("cuidador_id")
    turno_id = session.get("turno_id")

    if not cuidador_id or not turno_id:
        return redirect("/")

    db = get_db()
    data_hoje = date.today().isoformat()

    item = db.execute(
        """SELECT i.*, r.nome AS residente, t.nome AS tipo, t.natureza, t.unidade, t.faixa_min, t.faixa_max
           FROM item_rotina i
           JOIN residente r ON r.id = i.residente_id
           JOIN tipo_checkin t ON t.id = i.tipo_id
           WHERE i.id = ?""",
        (item_id,)
    ).fetchone()

    if not item or item["natureza"] != "medicao":
        return redirect("/lista")

    # Impede novo registro se já foi feito hoje (RN-03)
    ja_feito = db.execute(
        "SELECT id FROM checkin WHERE item_id = ? AND date(registrado_em) = ?",
        (item_id, data_hoje)
    ).fetchone()

    if ja_feito:
        return redirect("/lista")

    erro = None
    alerta_fora = False
    valor_digitado = ""
    confirmado = False

    if request.method == "POST":
        valor_str = request.form.get("valor", "").replace(",", ".").strip()
        observacao = request.form.get("observacao", "")
        confirmado_str = request.form.get("confirmado", "0")

        try:
            valor_float = float(valor_str)
            valor_digitado = valor_str

            min_val = item["faixa_min"]
            max_val = item["faixa_max"]
            esta_fora = (min_val is not None and valor_float < min_val) or (max_val is not None and valor_float > max_val)

            if esta_fora and confirmado_str != "1":
                alerta_fora = True
            else:
                salvar_checkin(
                    db, item_id, turno_id, cuidador_id,
                    status="realizado",
                    valor=valor_float,
                    fora=1 if esta_fora else 0,
                    observacao=observacao
                )
                return redirect("/lista")
        except ValueError:
            erro = "Informe o valor medido."

    hora_atual = HORA_DEMO or "09:40"
    status_item = "Atrasado" if item["horario"] < hora_atual else "Pendente"

    return render_template(
        "checkin-medicao.html",
        item=item,
        status_item=status_item,
        erro=erro,
        alerta_fora=alerta_fora,
        valor_digitado=valor_digitado
    )

# Rota para encerramento de turno e passagem de plantao (US-03)
@app.route("/turno/encerrar", methods=["GET", "POST"])
def turno_encerrar():
    from flask import session, redirect, request, render_template
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
    pendentes = [i for i in todos_itens if i["status_calculado"] in ["atrasado", "pendente"]]

    if request.method == "POST":
        passagem = request.form.get("passagem", "").strip()
        
        # Gera a lista de pendencias em texto (uma por linha)
        linhas_pendencias = []
        for p in pendentes:
            linhas_pendencias.append(f"{p['tipo']} — {p['residente']} ({p['horario']})")
        
        pendencias_texto = "\n".join(linhas_pendencias)
        agora_str = data_hoje + " " + hora_atual + ":00"

        cursor = db.cursor()
        cursor.execute(
            """UPDATE turno 
               SET encerrado_em = ?, passagem = ?, pendencias = ? 
               WHERE id = ?""",
            (agora_str, passagem, pendencias_texto, turno_id)
        )
        db.commit()

        session.clear()
        return redirect("/")

    return render_template(
        "encerrar-turno.html",
        cuidador=cuidador,
        pendentes=pendentes,
        hora_atual=hora_atual
    )


# ---------------------------------------------------------------------------
# API JSON para o app Flutter (fase 1). Usa a mesma sessão (cookie) das telas HTML.
# ---------------------------------------------------------------------------
import math
from datetime import date
from flask import jsonify, request, session, redirect, send_from_directory
from werkzeug.security import safe_join

PASTA_FLUTTER = PASTA / "flutter_web"

# Monta o cuidador em JSON só com campos públicos: nunca inclui o PIN nem o hash
def cuidador_em_json(linha):
    return {
        "id": linha["id"],
        "nome": linha["nome"],
        "iniciais": linha["iniciais"],
        "turno_padrao": linha["turno_padrao"],
    }

# Devolve a resposta 401 quando falta cuidador (ou turno) na sessão; None quando está tudo certo
def exigir_login(precisa_turno=False):
    if not session.get("cuidador_id") or (precisa_turno and not session.get("turno_id")):
        return jsonify(erro="Sessão expirada. Entre novamente."), 401
    return None

# Recusa POST que não venha em JSON: formulário de outro site não consegue enviar JSON sem preflight
def exigir_json():
    if not request.is_json:
        return jsonify(erro="Envie os dados em JSON."), 415
    return None

# Lista os cuidadores ativos para a tela de perfis
@app.route("/api/cuidadores")
def api_cuidadores():
    db = get_db()
    cuidadores = db.execute("SELECT * FROM cuidador WHERE ativo = 1").fetchall()
    return jsonify([cuidador_em_json(c) for c in cuidadores])

# Login por PIN com as mesmas regras da rota /pin (hash, limite de tentativas e bloqueio)
@app.route("/api/login", methods=["POST"])
def api_login():
    recusa = exigir_json()
    if recusa:
        return recusa

    dados = request.get_json(silent=True)
    dados = dados if isinstance(dados, dict) else {}
    cuidador_id = dados.get("cuidador_id")
    pin = dados.get("pin")
    id_valido = isinstance(cuidador_id, int) and not isinstance(cuidador_id, bool)
    pin_valido = isinstance(pin, str) and len(pin) == 4 and all(c in "0123456789" for c in pin)
    if not id_valido or not pin_valido:
        return jsonify(erro="Informe o cuidador e um PIN de 4 dígitos."), 400

    db = get_db()
    cuidador = db.execute("SELECT * FROM cuidador WHERE id = ? AND ativo = 1", (cuidador_id,)).fetchone()
    if not cuidador:
        return jsonify(erro="Cuidador não encontrado."), 404

    bloqueio = minutos_de_bloqueio(db, cuidador_id)
    if bloqueio > 0:
        return jsonify(
            erro=f"Acesso bloqueado por excesso de tentativas. Tente novamente em {bloqueio} min.",
            minutos=bloqueio,
        ), 429

    if not check_password_hash(cuidador["pin"], pin):
        restantes = registrar_falha(db, cuidador_id)
        if restantes == 0:
            return jsonify(
                erro=f"PIN incorreto. Acesso bloqueado por {MINUTOS_BLOQUEIO} minutos.",
                minutos=MINUTOS_BLOQUEIO,
            ), 429
        return jsonify(erro=f"PIN incorreto. Restam {restantes} tentativa(s).", restantes=restantes), 403

    zerar_tentativas(db, cuidador_id)
    session.clear()
    session["cuidador_id"] = cuidador_id

    turno_aberto = db.execute(
        "SELECT id FROM turno WHERE cuidador_id = ? AND encerrado_em IS NULL",
        (cuidador_id,)
    ).fetchone()
    if turno_aberto:
        session["turno_id"] = turno_aberto["id"]

    return jsonify(cuidador=cuidador_em_json(cuidador), turno_aberto=bool(turno_aberto))

# Reúne os dados do último turno encerrado (alertas, passagem e pendências) para a abertura do turno
def dados_da_abertura(db):
    ultimo_turno = db.execute(
        """SELECT t.*, c.nome AS cuidador_nome
           FROM turno t
           JOIN cuidador c ON c.id = t.cuidador_id
           WHERE t.encerrado_em IS NOT NULL
           ORDER BY t.encerrado_em DESC, t.id DESC LIMIT 1"""
    ).fetchone()

    alertas = []
    pendencias = []
    if ultimo_turno:
        linhas = db.execute(
            """SELECT c.status, c.valor, c.fora_da_faixa, c.motivo,
                      t.nome AS tipo_nome, t.unidade, r.nome AS residente_nome
               FROM checkin c
               JOIN item_rotina i ON i.id = c.item_id
               JOIN tipo_checkin t ON t.id = i.tipo_id
               JOIN residente r ON r.id = i.residente_id
               WHERE c.turno_id = ? AND (c.fora_da_faixa = 1 OR c.status = 'nao_realizado')""",
            (ultimo_turno["id"],)
        ).fetchall()
        alertas = [dict(linha) for linha in linhas]

        if ultimo_turno["pendencias"]:
            pendencias = [p.strip() for p in ultimo_turno["pendencias"].split("\n") if p.strip()]

    total_residentes = db.execute("SELECT COUNT(*) AS total FROM residente").fetchone()["total"]

    return {
        "ultimo_turno": {
            "cuidador_nome": ultimo_turno["cuidador_nome"],
            "encerrado_em": ultimo_turno["encerrado_em"],
            "passagem": ultimo_turno["passagem"],
        } if ultimo_turno else None,
        "alertas": alertas,
        "pendencias": pendencias,
        "total_residentes": total_residentes,
    }

# Dados da tela de abertura de turno
@app.route("/api/turno/abrir", methods=["GET"])
def api_turno_dados():
    recusa = exigir_login()
    if recusa:
        return recusa

    db = get_db()
    cuidador = db.execute("SELECT * FROM cuidador WHERE id = ?", (session["cuidador_id"],)).fetchone()
    if not cuidador:
        session.clear()
        return jsonify(erro="Sessão expirada. Entre novamente."), 401

    dados = dados_da_abertura(db)
    dados["cuidador"] = cuidador_em_json(cuidador)
    return jsonify(dados)

# Abre o turno do cuidador logado; se ele já tem um turno aberto, reaproveita esse turno
@app.route("/api/turno/abrir", methods=["POST"])
def api_turno_abrir():
    recusa = exigir_login() or exigir_json()
    if recusa:
        return recusa

    db = get_db()
    cuidador_id = session["cuidador_id"]
    existente = db.execute(
        "SELECT id FROM turno WHERE cuidador_id = ? AND encerrado_em IS NULL",
        (cuidador_id,)
    ).fetchone()
    if existente:
        session["turno_id"] = existente["id"]
        return jsonify(turno_id=existente["id"]), 200

    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO turno (cuidador_id, aberto_em) VALUES (?, ?)",
        (cuidador_id, HORA_DEMO or "09:40")
    )
    db.commit()
    session["turno_id"] = cursor.lastrowid
    return jsonify(turno_id=cursor.lastrowid), 201

# Itens do turno: os mesmos que a rota /lista mostra, com o status calculado pela RN-07
@app.route("/api/lista")
def api_lista():
    db = get_db()
    recusa = exigir_turno_aberto(db)
    if recusa:
        return recusa

    cuidador =db.execute("SELECT * FROM cuidador WHERE id = ?", (session["cuidador_id"],)).fetchone()
    if not cuidador:
        session.clear()
        return jsonify(erro="Sessão expirada. Entre novamente."), 401

    todos_itens = itens_do_dia(db, date.today().isoformat(), HORA_DEMO or "09:40")

    itens = []
    for item in todos_itens:
        status = "nao_realizado" if item["registro"] == "nao_realizado" else item["status_calculado"]
        itens.append({
            "id": str(item["id"]),
            "horario": item["horario"],
            "residente_id": str(item["residente_id"]),
            "residente": item["residente"],
            "tipo": item["tipo"],
            "natureza": item["natureza"],
            "unidade": item["unidade"],
            "faixa_min": item["faixa_min"],
            "faixa_max": item["faixa_max"],
            "status": status,
        })

    total = len(todos_itens)
    feitos = sum(1 for i in todos_itens if i["status_calculado"] == "feito")
    atrasados = sum(1 for i in todos_itens if i["status_calculado"] == "atrasado")

    return jsonify(
        cuidador=cuidador_em_json(cuidador),
        itens=itens,
        total=total,
        feitos=feitos,
        atrasados=atrasados,
        progresso=int((feitos / total) * 100) if total > 0 else 0,
    )

# Sai da sessão sem encerrar o turno (igual à rota /sair)
@app.route("/api/sair", methods=["POST"])
def api_sair():
    recusa = exigir_json()
    if recusa:
        return recusa
    session.clear()
    return "", 204

# ---------------------------------------------------------------------------
# API de registros (fase 2). Copia as regras das rotas HTML /checkin/... e /turno/encerrar
# sem alterá-las; cuidador e turno vêm sempre da sessão, nunca do corpo da requisição.
# ---------------------------------------------------------------------------

# Motivos aceitos para não realizado (RN-04): mesmas chaves e textos da rota /checkin/<id>/nao-realizado
MOTIVOS_NAO_REALIZADO = {
    "recusa": "Recusa do residente",
    "dormindo": "Residente dormindo",
    "material-indisponivel": "Material indisponível",
    "emergencia": "Emergência"
}

# Exige cuidador logado com o turno da sessão ainda aberto; turno encerrado ou de outro cuidador derruba a sessão
def exigir_turno_aberto(db):
    cuidador_id = session.get("cuidador_id")
    turno_id = session.get("turno_id")
    if not cuidador_id or not turno_id:
        return jsonify(erro="Sessão expirada. Entre novamente."), 401
    turno = db.execute(
        "SELECT id FROM turno WHERE id = ? AND cuidador_id = ? AND encerrado_em IS NULL",
        (turno_id, cuidador_id)
    ).fetchone()
    if not turno:
        session.clear()
        return jsonify(erro="Sessão expirada. Entre novamente."), 401
    return None

# Busca o item da rotina com residente, tipo e faixa (mesma consulta das rotas /checkin/...)
def buscar_item(db, item_id):
    return db.execute(
        """SELECT i.*, r.nome AS residente, t.nome AS tipo, t.natureza, t.unidade, t.faixa_min, t.faixa_max
           FROM item_rotina i
           JOIN residente r ON r.id = i.residente_id
           JOIN tipo_checkin t ON t.id = i.tipo_id
           WHERE i.id = ?""",
        (item_id,)
    ).fetchone()

# Indica se o item já tem registro no dia, de qualquer cuidador (RN-03)
def ja_registrado_hoje(db, item_id, data_hoje):
    return db.execute(
        "SELECT id FROM checkin WHERE item_id = ? AND date(registrado_em) = ?",
        (item_id, data_hoje)
    ).fetchone() is not None

# Converte o valor medido como a rota /medicao ("36,8" vira 36.8) e diz se está fora da faixa; ValueError se inválido
def avaliar_medicao(item, valor_bruto):
    if isinstance(valor_bruto, bool) or not isinstance(valor_bruto, (str, int, float)):
        raise ValueError("valor inválido")
    valor_float = float(str(valor_bruto).replace(",", ".").strip())
    if not math.isfinite(valor_float):
        raise ValueError("valor não finito")
    min_val = item["faixa_min"]
    max_val = item["faixa_max"]
    esta_fora = (min_val is not None and valor_float < min_val) or (max_val is not None and valor_float > max_val)
    return valor_float, esta_fora

# Lê um campo de texto opcional do corpo: ausente ou null vira "", outro tipo devolve None
def campo_texto(dados, nome):
    valor = dados.get(nome)
    if valor is None:
        return ""
    return valor if isinstance(valor, str) else None

# Checagens comuns dos registros: sessão com turno aberto, JSON, item existente e ainda não registrado hoje
def preparar_registro(item_id):
    db = get_db()
    recusa = exigir_turno_aberto(db) or exigir_json()
    if recusa:
        return None, None, recusa

    dados = request.get_json(silent=True)
    if not isinstance(dados, dict):
        return None, None, (jsonify(erro="Envie os dados como um objeto JSON."), 400)

    item = buscar_item(db, item_id)
    if not item:
        return None, None, (jsonify(erro="Item não encontrado."), 404)

    if ja_registrado_hoje(db, item_id, date.today().isoformat()):
        return None, None, (jsonify(erro="Este item já foi registrado hoje."), 409)

    return item, dados, None

# Registra uma tarefa realizada (inclui medicação e exercício, que no banco são tarefas)
@app.route("/api/checkin/<int:item_id>", methods=["POST"])
def api_checkin_tarefa(item_id):
    item, dados, recusa = preparar_registro(item_id)
    if recusa:
        return recusa

    if item["natureza"] == "medicao":
        return jsonify(erro="Este item é uma medição."), 400

    observacao = campo_texto(dados, "observacao")
    if observacao is None:
        return jsonify(erro="A observação deve ser texto."), 400

    salvar_checkin(get_db(), item_id, session["turno_id"], session["cuidador_id"], "realizado", observacao=observacao)
    return jsonify(status="feito"), 201

# Registra uma medição com o alerta em duas etapas da rota /medicao (US-09, US-13)
@app.route("/api/checkin/<int:item_id>/medicao", methods=["POST"])
def api_checkin_medicao(item_id):
    item, dados, recusa = preparar_registro(item_id)
    if recusa:
        return recusa

    if item["natureza"] != "medicao":
        return jsonify(erro="Este item não é uma medição."), 400

    observacao = campo_texto(dados, "observacao")
    confirmado = dados.get("confirmado", False)
    if observacao is None or not isinstance(confirmado, bool):
        return jsonify(erro="Observação deve ser texto e confirmado deve ser true ou false."), 400

    try:
        valor_float, esta_fora = avaliar_medicao(item, dados.get("valor"))
    except ValueError:
        return jsonify(erro="Informe o valor medido."), 400

    # 1ª etapa: valor fora da faixa sem confirmação não grava nada, só pede para confirmar
    if esta_fora and not confirmado:
        return jsonify(registrado=False, alerta_fora=True), 200

    salvar_checkin(
        get_db(), item_id, session["turno_id"], session["cuidador_id"],
        status="realizado",
        valor=valor_float,
        fora=1 if esta_fora else 0,
        observacao=observacao
    )
    return jsonify(status="feito", fora_da_faixa=esta_fora), 201

# Registra um item não realizado; o motivo precisa ser um dos aceitos pela rota HTML (US-11, RN-04)
@app.route("/api/checkin/<int:item_id>/nao-realizado", methods=["POST"])
def api_checkin_nao_realizado(item_id):
    item, dados, recusa = preparar_registro(item_id)
    if recusa:
        return recusa

    motivo = dados.get("motivo")
    if not isinstance(motivo, str) or motivo not in MOTIVOS_NAO_REALIZADO:
        return jsonify(erro="Escolha um motivo."), 400

    observacao = campo_texto(dados, "observacao")
    if observacao is None:
        return jsonify(erro="A observação deve ser texto."), 400

    salvar_checkin(
        get_db(), item_id, session["turno_id"], session["cuidador_id"],
        status="nao_realizado",
        motivo=MOTIVOS_NAO_REALIZADO[motivo],
        observacao=observacao
    )
    return jsonify(status="nao_realizado"), 201

# Encerra o turno como a rota /turno/encerrar: grava passagem e pendências e limpa a sessão (US-03)
@app.route("/api/turno/encerrar", methods=["POST"])
def api_turno_encerrar():
    db = get_db()
    recusa = exigir_turno_aberto(db) or exigir_json()
    if recusa:
        return recusa

    dados = request.get_json(silent=True)
    if not isinstance(dados, dict):
        return jsonify(erro="Envie os dados como um objeto JSON."), 400

    passagem = campo_texto(dados, "passagem")
    if passagem is None:
        return jsonify(erro="A passagem deve ser texto."), 400
    passagem = passagem.strip()

    hora_atual = HORA_DEMO or "09:40"
    data_hoje = date.today().isoformat()
    pendentes = [i for i in itens_do_dia(db, data_hoje, hora_atual) if i["status_calculado"] in ["atrasado", "pendente"]]
    linhas_pendencias = [f"{p['tipo']} — {p['residente']} ({p['horario']})" for p in pendentes]
    agora_str = data_hoje + " " + hora_atual + ":00"

    db.execute(
        """UPDATE turno
           SET encerrado_em = ?, passagem = ?, pendencias = ?
           WHERE id = ? AND encerrado_em IS NULL""",
        (agora_str, passagem, "\n".join(linhas_pendencias), session["turno_id"])
    )
    db.commit()

    session.clear()
    return jsonify(pendencias=linhas_pendencias), 200

# Serve o build web do Flutter em /app/ (o Flask redireciona /app para /app/ sozinho); caminho desconhecido volta para o index.html
@app.route("/app/")
@app.route("/app/<path:arquivo>")
def flutter_web(arquivo="index.html"):
    if not (PASTA_FLUTTER / "index.html").is_file():
        return "Build do Flutter não encontrado.", 404
    caminho = safe_join(str(PASTA_FLUTTER), arquivo)
    if not caminho or not Path(caminho).is_file():
        arquivo = "index.html"
    return send_from_directory(PASTA_FLUTTER, arquivo)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)