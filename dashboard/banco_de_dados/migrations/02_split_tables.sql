-- ══════════════════════════════════════════════════════════════
--  Caju Dashboard — Migração: separar transações por banco
--  Execute no SQL Editor do Supabase (menu lateral → SQL Editor)
--
--  O que este arquivo faz:
--    1. Cria transacoes_santander  (mesma estrutura de transacoes)
--    2. Cria transacoes_itau       (mesma estrutura de transacoes)
--    3. Migra dados existentes de transacoes → tabelas novas
--    4. Cria VIEW transacoes_view  (UNION das duas — leitura unificada)
--    5. Atualiza limpar_dados()    (limpa as duas tabelas)
--
--  Após executar, atualize o index.html para a versão nova.
--  A tabela original "transacoes" é mantida intacta até você
--  confirmar que tudo funciona — pode apagá-la depois com:
--    DROP TABLE public.transacoes CASCADE;
-- ══════════════════════════════════════════════════════════════


-- ──────────────────────────────────────────────────────────────
-- 1. TABELA: transacoes_santander
-- ──────────────────────────────────────────────────────────────
create table if not exists public.transacoes_santander (
  id         serial primary key,
  conta_id   integer references public.contas(id) on delete cascade,
  data       date not null,
  descricao  text default '',
  valor      numeric(15,2) not null,
  tipo       text not null check (tipo in ('receita','despesa','rendimento','transferencia')),
  fitid      text,
  created_at timestamptz default now(),
  unique (conta_id, fitid)
);

alter table public.transacoes_santander enable row level security;

create policy "txsant_select" on public.transacoes_santander
  for select using (auth.role() = 'authenticated');

create policy "txsant_insert_admin" on public.transacoes_santander
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

create policy "txsant_delete_admin" on public.transacoes_santander
  for delete using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

create policy "txsant_update_admin" on public.transacoes_santander
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );


-- ──────────────────────────────────────────────────────────────
-- 2. TABELA: transacoes_itau
-- ──────────────────────────────────────────────────────────────
create table if not exists public.transacoes_itau (
  id         serial primary key,
  conta_id   integer references public.contas(id) on delete cascade,
  data       date not null,
  descricao  text default '',
  valor      numeric(15,2) not null,
  tipo       text not null check (tipo in ('receita','despesa','rendimento','transferencia')),
  fitid      text,
  created_at timestamptz default now(),
  unique (conta_id, fitid)
);

alter table public.transacoes_itau enable row level security;

create policy "txitau_select" on public.transacoes_itau
  for select using (auth.role() = 'authenticated');

create policy "txitau_insert_admin" on public.transacoes_itau
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

create policy "txitau_delete_admin" on public.transacoes_itau
  for delete using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

create policy "txitau_update_admin" on public.transacoes_itau
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );


-- ──────────────────────────────────────────────────────────────
-- 3. MIGRAÇÃO — copia dados existentes para as novas tabelas
--    Identifica o banco de cada transação via JOIN com contas.
--    Seguro rodar múltiplas vezes (ON CONFLICT DO NOTHING).
-- ──────────────────────────────────────────────────────────────

-- 3a. Santander
insert into public.transacoes_santander
  (id, conta_id, data, descricao, valor, tipo, fitid, created_at)
select t.id, t.conta_id, t.data, t.descricao, t.valor, t.tipo, t.fitid, t.created_at
from public.transacoes t
join public.contas c on c.id = t.conta_id
where lower(c.banco) like '%santander%'
on conflict (conta_id, fitid) do nothing;

-- 3b. Itaú
insert into public.transacoes_itau
  (id, conta_id, data, descricao, valor, tipo, fitid, created_at)
select t.id, t.conta_id, t.data, t.descricao, t.valor, t.tipo, t.fitid, t.created_at
from public.transacoes t
join public.contas c on c.id = t.conta_id
where lower(c.banco) like '%ita%'   -- cobre "Itaú" e "Itau"
on conflict (conta_id, fitid) do nothing;

-- Relatório de migração (exibe no resultado da query)
select
  'transacoes_santander' as tabela, count(*) as registros from public.transacoes_santander
union all
select
  'transacoes_itau', count(*) from public.transacoes_itau
union all
select
  'transacoes (original)', count(*) from public.transacoes;


-- ──────────────────────────────────────────────────────────────
-- 4. VIEW: transacoes_view
--    Leitura unificada usada pelo dashboard para consultas
--    SQL externas (BI, relatórios). O index.html lê as tabelas
--    diretamente em paralelo; esta view é opcional mas útil.
-- ──────────────────────────────────────────────────────────────
create or replace view public.transacoes_view as
  select id, conta_id, data, descricao, valor, tipo, fitid, created_at,
         'Santander'::text as banco_origem
  from public.transacoes_santander
  union all
  select id, conta_id, data, descricao, valor, tipo, fitid, created_at,
         'Itaú'::text as banco_origem
  from public.transacoes_itau;


-- ──────────────────────────────────────────────────────────────
-- 5. ATUALIZA limpar_dados() — apaga as duas tabelas novas
-- ──────────────────────────────────────────────────────────────
create or replace function public.limpar_dados()
returns void language plpgsql security definer as $$
begin
  delete from public.transacoes_santander;
  delete from public.transacoes_itau;
  -- Mantém a tabela legada intacta; remova a linha abaixo
  -- somente após confirmar que a migração funcionou:
  -- delete from public.transacoes;
  delete from public.importacoes;
end;
$$;


-- ══════════════════════════════════════════════════════════════
--  CONCLUÍDO
--  Próximo passo: substitua o index.html pela versão atualizada.
--  Quando confirmar que tudo funciona, você pode apagar a tabela
--  original com:  DROP TABLE public.transacoes CASCADE;
-- ══════════════════════════════════════════════════════════════
