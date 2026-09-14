# Geratrix

Protótipo mobile de baixa fidelidade para registro de cuidados em Instituições de Longa Permanência para Idosos (ILPI).

O projeto utiliza HTML e CSS puros, com os estilos organizados conforme a metodologia BEM.

## Fluxos principais

- Seleção de perfil → PIN → abertura do turno → lista de tarefas.
- Lista → registro de tarefa → retorno à lista.
- Lista → registro de medição → retorno à lista.
- Lista → avaliação subjetiva → retorno à lista.
- Lista → conferência de medicação → retorno à lista.
- Registro de tarefa → justificativa de não realização.
- Lista → observação espontânea → retorno à lista.
- Lista → residente → histórico.
- Lista → encerramento do turno.
- Perfil gestor → painel de cuidadores.

## Telas

| Tela | Arquivo |
|---|---|
| Seleção de perfil | `index.html` |
| PIN | `pin.html` |
| Abertura de turno | `abrir-turno.html` |
| Lista de tarefas | `lista.html` |
| Residente | `residente.html` |
| Registro de tarefa | `checkin-tarefa.html` |
| Registro de medição | `checkin-medicao.html` |
| Avaliação subjetiva | `checkin-subjetivo.html` |
| Observação espontânea | `checkin-espontaneo.html` |
| Não realizado | `nao-realizado.html` |
| Medicação | `medicacao.html` |
| Histórico | `historico.html` |
| Encerramento de turno | `encerrar-turno.html` |
| Painel do gestor | `gestor.html` |

## Componentes e variações

| Bloco | Elementos | Modificadores |
|---|---|---|
| `page` | `page__header`, `page__title`, `page__subtitle`, `page__section-title`, `page__content` | `page--no-back`, `page--flush` |
| `back` | — | — |
| `topbar` | `topbar__back`, `topbar__label`, `topbar__title` | — |
| `nav` | `nav__item` | `nav__item--active` |
| `avatar` | — | `avatar--large` |
| `badge` | — | `badge--alert`, `badge--warning`, `badge--done` |
| `button` | — | `button--primary`, `button--block` |
| `card` | `card__info`, `card__title`, `card__text` | — |
| `user-list` | `user-list__item` | — |
| `list` | `list__item`, `list__text` | `list__text--link` |
| `filter` | `filter__item` | `filter__item--active` |
| `form` | `form__group`, `form__label`, `form__input`, `form__textarea`, `form__hint`, `form__error`, `form__option`, `form__option-text`, `form__actions` | `form__input--invalid`, `form__option--checked` |
| `shift` | `shift__label`, `shift__time`, `shift__unit`, `shift__from`, `shift__note` | — |
| `progress` | `progress__bar`, `progress__fill`, `progress__text` | — |
| `pin-user` | `pin-user__name` | — |
| `pin-display` | `pin-display__dot` | `pin-display__dot--filled` |
| `keypad` | `keypad__key` | `keypad__key--empty`, `keypad__key--action` |

## Organização

```text
css/
├── base/
├── layout/
└── components/

wireframes/
└── um arquivo PNG para cada tela