import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

# Cria, limpa e popula o banco de dados inicial para demonstração
def semear():
    pasta = Path(__file__).parent
    banco = pasta / "geratrix.db"
    schema = pasta / "schema.sql"

    conexao = sqlite3.connect(banco)
    cursor = conexao.cursor()

    with open(schema, "r", encoding="utf-8") as f:
        cursor.executescript(f.read())

    cuidadores = [
        (1, "Theo Casella Mendonça", "TCM", "Manhã", "1234", 1),
        (2, "Enzo Senatori", "ES", "Tarde", "1234", 1),
        (3, "Rafael de Oliveira Corrêa", "RC", "Noite", "1234", 1)
    ]
    cursor.executemany("INSERT INTO cuidador (id, nome, iniciais, turno_padrao, pin, ativo) VALUES (?, ?, ?, ?, ?, ?)", cuidadores)

    residentes = [
        (1, "Maria das Graças"),
        (2, "Antônio Ferreira"),
        (3, "José Augusto"),
        (4, "Terezinha Lima")
    ]
    cursor.executemany("INSERT INTO residente (id, nome) VALUES (?, ?)", residentes)

    tipos = [
        (1, "Medicação da manhã", "tarefa", None, None, None),
        (2, "Pressão arterial", "medicao", "mmHg", 90.0, 140.0),
        (3, "Troca de fraldas", "tarefa", None, None, None),
        (4, "Banho assistido", "tarefa", None, None, None),
        (5, "Glicemia capilar", "medicao", "mg/dL", 70.0, 180.0),
        (6, "Atividade física", "tarefa", None, None, None),
        (7, "Higiene oral", "tarefa", None, None, None),
        (8, "Temperatura", "medicao", "°C", 35.5, 37.5)
    ]
    cursor.executemany("INSERT INTO tipo_checkin (id, nome, natureza, unidade, faixa_min, faixa_max) VALUES (?, ?, ?, ?, ?, ?)", tipos)

    rotina = [
        (1, 1, 1, "08:30"),
        (2, 1, 2, "09:00"),
        (3, 4, 3, "09:00"),
        (4, 2, 4, "09:30"),
        (5, 3, 5, "09:45"),
        (6, 3, 6, "10:00"),
        (7, 1, 7, "10:30"),
        (8, 2, 8, "11:00")
    ]
    cursor.executemany("INSERT INTO item_rotina (id, residente_id, tipo_id, horario) VALUES (?, ?, ?, ?)", rotina)

    agora = datetime.now()
    ontem = agora - timedelta(days=1)
    
    ontem_19h = ontem.replace(hour=19, minute=0, second=0).strftime("%Y-%m-%d %H:%M:%S")
    hoje_07h = agora.replace(hour=7, minute=0, second=0).strftime("%Y-%m-%d %H:%M:%S")
    
    turno = (1, 3, ontem_19h, hoje_07h, "Dona Maria acordou duas vezes durante a noite. Sr. José recusou o lanche das 22h.", "Troca de fraldas -  Terezinha Lima (05:00)")
    cursor.execute("INSERT INTO turno (id, cuidador_id, aberto_em, encerrado_em, passagem, pendencias) VALUES (?, ?, ?, ?, ?, ?)", turno)

    ontem_22h10 = ontem.replace(hour=22, minute=10, second=0).strftime("%Y-%m-%d %H:%M:%S")
    ontem_22h40 = ontem.replace(hour=22, minute=40, second=0).strftime("%Y-%m-%d %H:%M:%S")
    ontem_23h05 = ontem.replace(hour=23, minute=5, second=0).strftime("%Y-%m-%d %H:%M:%S")

    checkins = [
        (1, 2, 1, 3, "realizado", 165.0, 1, None, None, ontem_22h10),
        (2, 5, 1, 3, "realizado", 250.0, 1, None, None, ontem_22h40),
        (3, 4, 1, 3, "nao_realizado", None, 0, "dormindo", None, ontem_23h05)
    ]
    cursor.executemany("INSERT INTO checkin (id, item_id, turno_id, cuidador_id, status, valor, fora_da_faixa, motivo, observacao, registrado_em) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", checkins)

    conexao.commit()
    conexao.close()
    print("Banco recriado em geratrix.db: 3 cuidadores, 4 residentes, 8 itens de rotina.")

if __name__ == "__main__":
    semear()