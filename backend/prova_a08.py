# Prova da A08: tenta alterar e apagar um check-in direto no banco; os triggers devem recusar as duas operações
import sqlite3

conexao = sqlite3.connect("geratrix.db")
print("check-in 1 antes: ", conexao.execute("SELECT id, status, valor FROM checkin WHERE id = 1").fetchone())

for descricao, comando in [
    ("alterar o valor da medição", "UPDATE checkin SET valor = 120 WHERE id = 1"),
    ("apagar o registro", "DELETE FROM checkin WHERE id = 1"),
]:
    try:
        conexao.execute(comando)
        print(f"FALHOU: o banco aceitou {descricao}")
    except sqlite3.DatabaseError as erro:
        print(f"PROTEGIDO: tentativa de {descricao} recusada -> {erro}")
    conexao.rollback()  # nunca grava nada: a prova não altera o banco em nenhum caso

print("check-in 1 depois:", conexao.execute("SELECT id, status, valor FROM checkin WHERE id = 1").fetchone())
conexao.close()