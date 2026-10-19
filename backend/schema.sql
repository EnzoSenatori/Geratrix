-- Geratrix MVP de apresentação (v0)
-- Rodar este arquivo apaga e recria o banco inteiro.
DROP TABLE IF EXISTS checkin;
DROP TABLE IF EXISTS turno;
DROP TABLE IF EXISTS item_rotina;
DROP TABLE IF EXISTS tipo_checkin;
DROP TABLE IF EXISTS residente;
DROP TABLE IF EXISTS cuidador;

CREATE TABLE cuidador (
    id INTEGER PRIMARY KEY,
    nome TEXT NOT NULL,
    iniciais TEXT NOT NULL,
    turno_padrao TEXT NOT NULL, -- Manhã, Tarde ou Noite
    pin TEXT NOT NULL,
    ativo INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE residente (
    id INTEGER PRIMARY KEY,
    nome TEXT NOT NULL
);

CREATE TABLE tipo_checkin (
    id INTEGER PRIMARY KEY,
    nome TEXT NOT NULL,
    natureza TEXT NOT NULL CHECK (natureza IN ('tarefa', 'medicao')),
    unidade TEXT, -- só para medição
    faixa_min REAL, -- só para medição
    faixa_max REAL -- só para medição
);

CREATE TABLE item_rotina (
    id INTEGER PRIMARY KEY,
    residente_id INTEGER NOT NULL REFERENCES residente(id),
    tipo_id INTEGER NOT NULL REFERENCES tipo_checkin(id),
    horario TEXT NOT NULL -- o que está previsto para o dia
);

CREATE TABLE turno (
    id INTEGER PRIMARY KEY,
    cuidador_id INTEGER NOT NULL REFERENCES cuidador(id),
    aberto_em TEXT NOT NULL, -- HH:MM
    encerrado_em TEXT,
    passagem TEXT, -- escrita pelo cuidador ao encerrar
    pendencias TEXT -- gerada pelo sistema ao encerrar, uma por linha
);

CREATE TABLE checkin (
    id INTEGER PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES item_rotina(id),
    turno_id INTEGER NOT NULL REFERENCES turno(id),
    cuidador_id INTEGER NOT NULL REFERENCES cuidador(id),
    status TEXT NOT NULL CHECK (status IN ('realizado', 'nao_realizado')),
    valor REAL, -- só para medição
    fora_da_faixa INTEGER NOT NULL DEFAULT 0, -- só para medição
    motivo TEXT, -- só para não realizado
    observacao TEXT,
    registrado_em TEXT NOT NULL
);

-- RN-02 check-in é imutável: o próprio banco recusa alteração e exclusão.
CREATE TRIGGER checkin_sem_update BEFORE UPDATE ON checkin
BEGIN
    SELECT RAISE (ABORT, 'Check-in é imutável');
END;

CREATE TRIGGER checkin_sem_delete BEFORE DELETE ON checkin
BEGIN
    SELECT RAISE (ABORT, 'Check-in é imutável');
END;