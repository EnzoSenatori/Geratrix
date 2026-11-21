import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from apoio import copiar_backend

# Quantas linhas PROTEGIDO cada prova precisa mostrar (a A08 testa UPDATE e DELETE)
PROVAS = {"prova_a01.py": 1, "prova_a08.py": 2}


# Roda uma prova na cópia do backend, mostra a saída como ela sai e devolve a lista de problemas
def rodar_prova(pasta, nome, minimo_protegido):
    ambiente = dict(os.environ, PYTHONIOENCODING="utf-8")
    ambiente.pop("SECRET_KEY", None)
    resultado = subprocess.run(
        [sys.executable, nome], cwd=pasta, env=ambiente,
        capture_output=True, text=True, encoding="utf-8"
    )
    print(f"===== {nome} =====")
    print(resultado.stdout, end="")
    if resultado.stderr:
        print(resultado.stderr, end="", file=sys.stderr)

    problemas = []
    if resultado.returncode != 0:
        problemas.append(f"terminou com código {resultado.returncode}")
    if "VULNERÁVEL" in resultado.stdout or "FALHOU" in resultado.stdout:
        problemas.append("a saída acusa VULNERÁVEL/FALHOU")
    protegidos = resultado.stdout.count("PROTEGIDO")
    if protegidos < minimo_protegido:
        problemas.append(f"esperava {minimo_protegido} PROTEGIDO, veio {protegidos}")
    return problemas


# Cria o banco da cópia, roda as provas e sai com código 1 se alguma não provar a proteção
def principal():
    pasta = copiar_backend()
    try:
        subprocess.run(
            [sys.executable, "-c", "from seed import semear; semear()"],
            cwd=pasta, check=True, capture_output=True
        )
        falhas = {}
        for nome, minimo in PROVAS.items():
            problemas = rodar_prova(pasta, nome, minimo)
            if problemas:
                falhas[nome] = problemas
    finally:
        shutil.rmtree(pasta, ignore_errors=True)

    print("===== resultado =====")
    if falhas:
        for nome, problemas in falhas.items():
            print(f"FALHA em {nome}: {'; '.join(problemas)}")
        sys.exit(1)
    print("Provas A01 e A08: PROTEGIDO")


if __name__ == "__main__":
    principal()
