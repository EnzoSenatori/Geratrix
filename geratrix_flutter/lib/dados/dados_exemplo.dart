import '../models/cuidador.dart';
import '../models/item_rotina.dart';
import '../models/residente.dart';

// Residentes cadastrados na instituição (baseados no seed.py)
const mariaDasGracas = Residente(
  id: '1',
  nome: 'Maria das Graças',
  quarto: 'Quarto 101',
  iniciais: 'MG',
  alergias: ['Dipirona', 'Frutos do Mar'],
  restricoesAlimentares: ['Dieta hipossódica (pouco sal)', 'Pouco açúcar'],
  contatoEmergencia: 'Filha: (11) 99999-1111',
  observacoesMedicas: 'Hipertensa, diabetes tipo 2 e mobilidade reduzida.',
);

const antonioFerreira = Residente(
  id: '2',
  nome: 'Antônio Ferreira',
  quarto: 'Quarto 102',
  iniciais: 'AF',
  alergias: [],
  restricoesAlimentares: [],
  contatoEmergencia: 'Esposa: (11) 99999-2222',
  observacoesMedicas: 'Sem observações críticas.',
);

const joseAugusto = Residente(
  id: '3',
  nome: 'José Augusto',
  quarto: 'Quarto 103',
  iniciais: 'JA',
  alergias: [],
  restricoesAlimentares: ['Pouco açúcar'],
  contatoEmergencia: 'Filho: (11) 99999-3333',
  observacoesMedicas: 'Monitoramento diário de glicemia.',
);

const terezinhaLima = Residente(
  id: '4',
  nome: 'Terezinha Lima',
  quarto: 'Quarto 104',
  iniciais: 'TL',
  alergias: [],
  restricoesAlimentares: [],
  contatoEmergencia: 'Sobrinha: (11) 99999-4444',
  observacoesMedicas: 'Cuidados gerais de rotina.',
);

// Cuidadores cadastrados
const cuidadores = [
  Cuidador(nome: 'Theo Casella Mendonça', iniciais: 'TCM', turnoPadrao: 'Manhã', pin: '1234', ativo: true),
  Cuidador(nome: 'Enzo Senatori', iniciais: 'ES', turnoPadrao: 'Tarde', pin: '1234', ativo: true),
  Cuidador(nome: 'Rafael de Oliveira Corrêa', iniciais: 'RC', turnoPadrao: 'Noite', pin: '1234', ativo: true),
  Cuidador(nome: 'Maria da Silva', iniciais: 'MS', turnoPadrao: 'Folga', pin: '0000', ativo: false),
];

// Rotina do dia, igual ao seed.py; status calculado como no backend, com a hora de demonstração 09:40
const itensDoDia = [
  ItemRotina(
    id: '1',
    horario: '08:30',
    tipo: 'Medicação da manhã',
    natureza: 'medicacao',
    residente: mariaDasGracas,
    status: 'atrasado',
  ),
  ItemRotina(
    id: '2',
    horario: '09:00',
    tipo: 'Pressão arterial',
    natureza: 'medicao',
    residente: mariaDasGracas,
    status: 'atrasado',
    unidade: 'mmHg',
    faixaMin: 90,
    faixaMax: 140,
  ),
  ItemRotina(
    id: '3',
    horario: '09:00',
    tipo: 'Troca de fraldas',
    natureza: 'tarefa',
    residente: terezinhaLima,
    status: 'atrasado',
  ),
  ItemRotina(
    id: '4',
    horario: '09:30',
    tipo: 'Banho assistido',
    natureza: 'tarefa',
    residente: antonioFerreira,
    status: 'atrasado',
  ),
  ItemRotina(
    id: '5',
    horario: '09:45',
    tipo: 'Glicemia capilar',
    natureza: 'medicao',
    residente: joseAugusto,
    status: 'pendente',
    unidade: 'mg/dL',
    faixaMin: 70,
    faixaMax: 180,
  ),
  ItemRotina(
    id: '6',
    horario: '10:00',
    tipo: 'Atividade física',
    natureza: 'exercicio',
    residente: joseAugusto,
    status: 'pendente',
  ),
  ItemRotina(
    id: '7',
    horario: '10:30',
    tipo: 'Higiene oral',
    natureza: 'tarefa',
    residente: mariaDasGracas,
    status: 'pendente',
  ),
  ItemRotina(
    id: '8',
    horario: '11:00',
    tipo: 'Temperatura',
    natureza: 'medicao',
    residente: antonioFerreira,
    status: 'pendente',
    unidade: '°C',
    faixaMin: 35.5,
    faixaMax: 37.5,
  ),
];