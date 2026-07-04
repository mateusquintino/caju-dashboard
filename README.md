# Cajupar — Fluxo de Caixa

Dashboard financeiro das empresas do grupo (Caju, CPD, Foster Burguer, Caminito, Nazo e outras). A aplicação web exibe o fluxo de caixa lendo os dados de um banco de dados no Supabase.

O projeto tem duas partes:

1. **Dashboard** (`dashboard/`) — aplicação web que exibe o fluxo de caixa. Roda no navegador e lê os dados diretamente do Supabase.
2. **Banco de dados** (`banco_de_dados/`) — scripts SQL para criar e manter as tabelas no Supabase.

---

## Estrutura do projeto

```
Fluxo de caixa/
├── index.html                    ← entrada do site: redireciona p/ dashboard/ (GitHub Pages)
├── README.md                     ← este arquivo
├── .gitignore
│
├── dashboard/                    ← aplicação web (frontend)
│   ├── index.html                ← dashboard principal
│   ├── favicon.svg
│   └── assets/                   ← logos e imagens
│
├── banco_de_dados/               ← scripts SQL do Supabase
│   ├── 01_setup.sql              ← criação inicial das tabelas
│   ├── migrations/
│   │   └── 02_split_tables.sql   ← separação de transações por banco
│   ├── seeds/
│   │   └── seed_contas.sql       ← cadastro inicial de contas
│   └── diagnosticos/
│       └── diagnostico_contas.sql
│
└── arquivo/                      ← versões antigas do dashboard (referência)
    ├── caju-dashboard_16.html
    └── caju-dashboard_17.html
```

---

## Como usar

### Dashboard

Abra `dashboard/index.html` no navegador. Ele se conecta ao Supabase e exibe o fluxo de caixa.

### Banco de dados (Supabase)

No SQL Editor do Supabase, execute na ordem:

1. `banco_de_dados/01_setup.sql`
2. `banco_de_dados/migrations/02_split_tables.sql`
3. `banco_de_dados/seeds/seed_contas.sql` (opcional — cadastro inicial de contas)

O script `banco_de_dados/diagnosticos/diagnostico_contas.sql` ajuda a identificar contas com configuração incorreta.
