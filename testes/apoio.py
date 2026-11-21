import shutil
import tempfile
from pathlib import Path

PASTA_BACKEND = Path(__file__).resolve().parent.parent / "backend"
ARQUIVOS = ["app.py", "seed.py", "schema.sql", "prova_a01.py", "prova_a08.py"]


# Copia o backend (sem o geratrix.db) para uma pasta temporária e devolve o caminho dela
def copiar_backend():
    destino = Path(tempfile.mkdtemp(prefix="geratrix_teste_"))
    for nome in ARQUIVOS:
        shutil.copy2(PASTA_BACKEND / nome, destino / nome)
    shutil.copytree(PASTA_BACKEND / "templates", destino / "templates")
    return destino
