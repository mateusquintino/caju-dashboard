-- ══════════════════════════════════════════════════════════════
--  Migração 04 — View unificada de transações
--  Une transacoes_santander + transacoes_itau numa única fonte, para
--  as abas "Movimentações" e "Tarifa Bancária" consultarem com
--  paginação/filtro no servidor (em vez de baixar TODAS as transações
--  para o navegador). Usa security_invoker para respeitar o RLS das
--  tabelas base.
--
--  Já aplicada no projeto via MCP. Mantida aqui para versionamento.
--  Depende dos índices da migração 03 (idx_tx_*_data).
-- ══════════════════════════════════════════════════════════════

create or replace view public.vw_transacoes
with (security_invoker = on) as
  select id, conta_id, data, descricao, valor, tipo, fitid, 'santander'::text as fonte
    from public.transacoes_santander
  union all
  select id, conta_id, data, descricao, valor, tipo, fitid, 'itau'::text as fonte
    from public.transacoes_itau;

grant select on public.vw_transacoes to anon, authenticated;
