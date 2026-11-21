# Testes automatizados da API JSON (fases 1 e 2) com o test_client do Flask, num banco temporário
import contextlib
import importlib
import io
import json
import shutil
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from apoio import copiar_backend

PASTA = None
app_mod = None
seed_mod = None


# Importa uma cópia do app.py de uma pasta temporária: o banco nasce lá, nunca no backend/geratrix.db
def setUpModule():
    global PASTA, app_mod, seed_mod
    PASTA = copiar_backend()
    sys.path.insert(0, str(PASTA))
    for nome in ("app", "seed"):
        sys.modules.pop(nome, None)
    with contextlib.redirect_stdout(io.StringIO()):
        app_mod = importlib.import_module("app")
    seed_mod = importlib.import_module("seed")
    banco = Path(app_mod.BANCO).resolve()
    if PASTA.resolve() not in banco.parents:
        raise RuntimeError(f"Banco fora da pasta temporária: {banco}")
    app_mod.app.config["TESTING"] = True


# Apaga a pasta temporária com o banco de teste
def tearDownModule():
    sys.path.remove(str(PASTA))
    for nome in ("app", "seed"):
        sys.modules.pop(nome, None)
    shutil.rmtree(PASTA, ignore_errors=True)


class TesteApi(unittest.TestCase):

    # Recria o banco do zero antes de cada teste (o schema.sql apaga tudo; proteger_pins recria tentativa_pin)
    def setUp(self):
        with contextlib.redirect_stdout(io.StringIO()):
            seed_mod.semear()
        app_mod.proteger_pins()
        self.cliente = app_mod.app.test_client()

    # Consulta direta ao banco de teste, para conferir o que a API gravou
    def consultar(self, sql, parametros=()):
        conexao = sqlite3.connect(app_mod.BANCO)
        conexao.row_factory = sqlite3.Row
        try:
            return conexao.execute(sql, parametros).fetchall()
        finally:
            conexao.close()

    # Quantas linhas existem na tabela checkin
    def total_checkins(self):
        return self.consultar("SELECT COUNT(*) AS n FROM checkin")[0]["n"]

    # Faz login pela API e devolve a resposta
    def entrar(self, cliente, cuidador_id, pin="1234"):
        return cliente.post("/api/login", json={"cuidador_id": cuidador_id, "pin": pin})

    # Faz login e abre o turno; devolve o id do turno aberto
    def entrar_com_turno(self, cliente, cuidador_id):
        self.assertEqual(self.entrar(cliente, cuidador_id).status_code, 200)
        resposta = cliente.post("/api/turno/abrir", json={})
        self.assertIn(resposta.status_code, (200, 201))
        return resposta.get_json()["turno_id"]

    # /api/cuidadores só devolve campos públicos: nada de PIN nem hash
    def test_cuidadores_sem_pin(self):
        resposta = self.cliente.get("/api/cuidadores")
        self.assertEqual(resposta.status_code, 200)
        cuidadores = resposta.get_json()
        self.assertEqual(len(cuidadores), 3)
        for cuidador in cuidadores:
            self.assertEqual(set(cuidador), {"id", "nome", "iniciais", "turno_padrao"})
        texto = resposta.get_data(as_text=True)
        self.assertNotIn("pin", texto)
        self.assertNotIn("scrypt:", texto)

    # PIN certo entra (200) sem devolver PIN nem hash
    def test_login_certo(self):
        resposta = self.entrar(self.cliente, 1)
        self.assertEqual(resposta.status_code, 200)
        dados = resposta.get_json()
        self.assertEqual(dados["cuidador"]["id"], 1)
        self.assertFalse(dados["turno_aberto"])
        texto = resposta.get_data(as_text=True)
        self.assertNotIn("pin", texto)
        self.assertNotIn("scrypt:", texto)

    # PIN errado: 403 com as tentativas restantes; no 5º erro, 429; depois, até o PIN certo é bloqueado
    def test_login_errado_e_bloqueio(self):
        for restantes in (4, 3, 2, 1):
            resposta = self.entrar(self.cliente, 1, "0000")
            self.assertEqual(resposta.status_code, 403)
            self.assertEqual(resposta.get_json()["erro"], f"PIN incorreto. Restam {restantes} tentativa(s).")

        resposta = self.entrar(self.cliente, 1, "0000")
        self.assertEqual(resposta.status_code, 429)
        self.assertEqual(resposta.get_json()["erro"], "PIN incorreto. Acesso bloqueado por 5 minutos.")

        resposta = self.entrar(self.cliente, 1, "1234")
        self.assertEqual(resposta.status_code, 429)
        self.assertEqual(
            resposta.get_json()["erro"],
            "Acesso bloqueado por excesso de tentativas. Tente novamente em 5 min.",
        )
        self.assertEqual(self.cliente.get("/api/lista").status_code, 401)

    # Cuidador inexistente dá 404 e PIN fora do formato dá 400
    def test_login_dados_invalidos(self):
        self.assertEqual(self.entrar(self.cliente, 99).status_code, 404)
        self.assertEqual(self.entrar(self.cliente, 1, "12a4").status_code, 400)
        self.assertEqual(self.cliente.post("/api/login", json={"cuidador_id": "1", "pin": "1234"}).status_code, 400)

    # Rotas que exigem login respondem 401 sem sessão (e as de turno também sem turno aberto)
    def test_401_sem_sessao(self):
        rotas = [
            ("get", "/api/lista"),
            ("get", "/api/turno/abrir"),
            ("post", "/api/turno/abrir"),
            ("post", "/api/checkin/3"),
            ("post", "/api/checkin/2/medicao"),
            ("post", "/api/checkin/4/nao-realizado"),
            ("post", "/api/turno/encerrar"),
        ]
        for metodo, rota in rotas:
            with self.subTest(rota=rota, metodo=metodo):
                resposta = getattr(self.cliente, metodo)(rota, json={})
                self.assertEqual(resposta.status_code, 401)
                self.assertEqual(resposta.get_json()["erro"], "Sessão expirada. Entre novamente.")

        # Logado, mas sem turno aberto: lista e registros continuam 401
        self.assertEqual(self.entrar(self.cliente, 1).status_code, 200)
        self.assertEqual(self.cliente.get("/api/lista").status_code, 401)
        self.assertEqual(self.cliente.post("/api/checkin/3", json={}).status_code, 401)

    # Todo POST exige Content-Type: application/json (415), mesmo com sessão e turno aberto
    def test_415_sem_json(self):
        self.assertEqual(self.cliente.post("/api/login", data={"cuidador_id": "1", "pin": "1234"}).status_code, 415)
        self.entrar_com_turno(self.cliente, 1)
        rotas = [
            "/api/turno/abrir",
            "/api/checkin/3",
            "/api/checkin/2/medicao",
            "/api/checkin/4/nao-realizado",
            "/api/turno/encerrar",
            "/api/sair",
        ]
        for rota in rotas:
            for corpo in ({"data": {"valor": "120"}}, {"data": "{}", "content_type": "text/plain"}):
                with self.subTest(rota=rota, corpo=corpo):
                    resposta = self.cliente.post(rota, **corpo)
                    self.assertEqual(resposta.status_code, 415)
                    self.assertEqual(resposta.get_json()["erro"], "Envie os dados em JSON.")
        self.assertEqual(self.total_checkins(), 3)
        self.assertEqual(self.cliente.get("/api/lista").status_code, 200)

    # Corpo que não é objeto JSON dá 400
    def test_400_corpo_invalido(self):
        self.entrar_com_turno(self.cliente, 1)
        resposta = self.cliente.post("/api/checkin/3", data=json.dumps([1, 2]), content_type="application/json")
        self.assertEqual(resposta.status_code, 400)
        self.assertEqual(self.cliente.post("/api/checkin/3", json={"observacao": 5}).status_code, 400)
        self.assertEqual(self.cliente.post("/api/checkin/99", json={}).status_code, 404)
        self.assertEqual(self.total_checkins(), 3)

    # Cuidador e turno gravados vêm da sessão, mesmo com ids forjados no corpo
    def test_autoria_vem_da_sessao(self):
        turno_id = self.entrar_com_turno(self.cliente, 1)
        forjado = {"cuidador_id": 3, "turno_id": 1}

        r1 = self.cliente.post("/api/checkin/3", json={**forjado, "observacao": "ok"})
        r2 = self.cliente.post("/api/checkin/5/medicao", json={**forjado, "valor": "120"})
        r3 = self.cliente.post("/api/checkin/4/nao-realizado", json={**forjado, "motivo": "dormindo"})
        self.assertEqual([r1.status_code, r2.status_code, r3.status_code], [201, 201, 201])

        linhas = self.consultar("SELECT item_id, cuidador_id, turno_id, motivo FROM checkin WHERE id > 3 ORDER BY id")
        self.assertEqual([l["item_id"] for l in linhas], [3, 5, 4])
        for linha in linhas:
            self.assertEqual(linha["cuidador_id"], 1)
            self.assertEqual(linha["turno_id"], turno_id)
        self.assertEqual(linhas[2]["motivo"], "Residente dormindo")

    # Motivo de não realizado fora da lista dá 400 e não grava
    def test_nao_realizado_motivo_invalido(self):
        self.entrar_com_turno(self.cliente, 1)
        for corpo in ({}, {"motivo": "inventado"}, {"motivo": 1}):
            with self.subTest(corpo=corpo):
                resposta = self.cliente.post("/api/checkin/4/nao-realizado", json=corpo)
                self.assertEqual(resposta.status_code, 400)
                self.assertEqual(resposta.get_json()["erro"], "Escolha um motivo.")
        self.assertEqual(self.total_checkins(), 3)

    # Item já registrado no dia dá 409, para o mesmo cuidador e para outro, sem gravar de novo
    def test_checkin_duplicado_409(self):
        self.entrar_com_turno(self.cliente, 1)
        self.assertEqual(self.cliente.post("/api/checkin/3", json={}).status_code, 201)
        total = self.total_checkins()

        resposta = self.cliente.post("/api/checkin/3", json={})
        self.assertEqual(resposta.status_code, 409)
        self.assertEqual(resposta.get_json()["erro"], "Este item já foi registrado hoje.")

        outro = app_mod.app.test_client()
        self.entrar_com_turno(outro, 2)
        self.assertEqual(outro.post("/api/checkin/3", json={}).status_code, 409)
        self.assertEqual(outro.post("/api/checkin/3/nao-realizado", json={"motivo": "recusa"}).status_code, 409)
        self.assertEqual(self.total_checkins(), total)

        itens = {i["id"]: i["status"] for i in outro.get("/api/lista").get_json()["itens"]}
        self.assertEqual(itens["3"], "feito")

    # Medição fora da faixa: 1º envio só alerta (nada gravado); com confirmado=true grava fora_da_faixa=1
    def test_medicao_fora_da_faixa_em_duas_etapas(self):
        self.entrar_com_turno(self.cliente, 1)
        total = self.total_checkins()

        resposta = self.cliente.post("/api/checkin/2/medicao", json={"valor": "165"})
        self.assertEqual(resposta.status_code, 200)
        self.assertEqual(resposta.get_json(), {"registrado": False, "alerta_fora": True})
        self.assertEqual(self.total_checkins(), total)

        resposta = self.cliente.post("/api/checkin/2/medicao", json={"valor": "165", "confirmado": True})
        self.assertEqual(resposta.status_code, 201)
        self.assertEqual(resposta.get_json(), {"status": "feito", "fora_da_faixa": True})
        linha = self.consultar("SELECT valor, fora_da_faixa FROM checkin WHERE item_id = 2 ORDER BY id DESC LIMIT 1")[0]
        self.assertEqual((linha["valor"], linha["fora_da_faixa"]), (165.0, 1))

    # Medição dentro da faixa grava direto; vírgula decimal é aceita; valor inválido dá 400
    def test_medicao_valores(self):
        self.entrar_com_turno(self.cliente, 1)
        for valor in ("abc", "nan", "inf", "", None, True):
            with self.subTest(valor=valor):
                resposta = self.cliente.post("/api/checkin/8/medicao", json={"valor": valor})
                self.assertEqual(resposta.status_code, 400)
                self.assertEqual(resposta.get_json()["erro"], "Informe o valor medido.")

        resposta = self.cliente.post("/api/checkin/8/medicao", json={"valor": "36,8"})
        self.assertEqual(resposta.status_code, 201)
        self.assertEqual(resposta.get_json(), {"status": "feito", "fora_da_faixa": False})
        linha = self.consultar("SELECT valor, fora_da_faixa FROM checkin WHERE item_id = 8")[0]
        self.assertEqual((linha["valor"], linha["fora_da_faixa"]), (36.8, 0))

        self.assertEqual(self.cliente.post("/api/checkin/3/medicao", json={"valor": "1"}).status_code, 400)
        self.assertEqual(self.cliente.post("/api/checkin/2", json={}).status_code, 400)

    # Encerrar grava passagem e pendências, derruba a sessão e o próximo login vai para abrir turno
    def test_encerrar_turno(self):
        turno_id = self.entrar_com_turno(self.cliente, 1)
        self.assertEqual(self.cliente.post("/api/checkin/3", json={}).status_code, 201)

        resposta = self.cliente.post("/api/turno/encerrar", json={"passagem": "  Plantão tranquilo.  "})
        self.assertEqual(resposta.status_code, 200)
        pendencias = resposta.get_json()["pendencias"]
        self.assertTrue(pendencias)
        self.assertFalse(any(p.startswith("Troca de fraldas") for p in pendencias))

        turno = self.consultar("SELECT encerrado_em, passagem, pendencias FROM turno WHERE id = ?", (turno_id,))[0]
        self.assertIsNotNone(turno["encerrado_em"])
        self.assertEqual(turno["passagem"], "Plantão tranquilo.")
        self.assertEqual(turno["pendencias"].split("\n"), pendencias)

        self.assertEqual(self.cliente.get("/api/lista").status_code, 401)
        self.assertEqual(self.cliente.post("/api/turno/encerrar", json={}).status_code, 401)

        resposta = self.entrar(self.cliente, 1)
        self.assertEqual(resposta.status_code, 200)
        self.assertFalse(resposta.get_json()["turno_aberto"])
        abertura = self.cliente.get("/api/turno/abrir").get_json()
        self.assertEqual(abertura["ultimo_turno"]["passagem"], "Plantão tranquilo.")


if __name__ == "__main__":
    unittest.main()
