-- ══════════════════════════════════════════════════════════════
--  Migração 03 — Índices de performance
--  Objetivo: acelerar a função dashboard_saldos (e demais consultas
--  por conta/período), que agrega as transações por conta_id filtrando
--  por data. Sem estes índices, cada carregamento do dashboard faz uma
--  varredura completa das tabelas de transações.
--
--  Como usar: Supabase → SQL Editor → New query → cole tudo → Run.
--  Seguro rodar mais de uma vez (IF NOT EXISTS).
-- ══════════════════════════════════════════════════════════════

-- Santander: agregação por conta + filtro/ordenção por data
create index if not exists idx_tx_sant_conta_data
  on public.transacoes_santander (conta_id, data);
create index if not exists idx_tx_sant_data
  on public.transacoes_santander (data);

-- Itaú
create index if not exists idx_tx_itau_conta_data
  on public.transacoes_itau (conta_id, data);
create index if not exists idx_tx_itau_data
  on public.transacoes_itau (data);

-- Tabela legada (só cria o índice se a tabela ainda existir)
do $$
begin
  if exists (select 1 from information_schema.tables
             where table_schema='public' and table_name='transacoes') then
    create index if not exists idx_tx_conta_data
      on public.transacoes (conta_id, data);
  end if;
end $$;

-- Atualiza estatísticas do planejador (opcional, ajuda o Postgres a
-- escolher os novos índices imediatamente).
analyze public.transacoes_santander;
analyze public.transacoes_itau;
