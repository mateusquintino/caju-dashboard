-- ══════════════════════════════════════════════════════════════
--  Migração 06 — Grupo de acesso, empresas vinculadas e permissões
--
--  Adiciona à tabela public.profiles as colunas que a nova tela de
--  Gestão de Usuários usa:
--    • grupo       → texto (Financeiro, RH, Diretoria, Sócio proprietário)
--    • empresas    → jsonb, lista de empresas vinculadas
--                    ex.: ["MULT 01 - CPD","CAJU 01 - ASN"]
--    • permissoes  → jsonb, mapa módulo → nível ('view' | 'edit' | 'none')
--                    ex.: {"Fluxo de caixa":"edit","Usuários":"none"}
--
--  Executar no SQL Editor do Supabase (projeto caju-dashboard).
--  Idempotente: pode rodar mais de uma vez sem erro.
-- ══════════════════════════════════════════════════════════════

alter table public.profiles
  add column if not exists grupo      text,
  add column if not exists empresas   jsonb not null default '[]'::jsonb,
  add column if not exists permissoes jsonb not null default '{}'::jsonb;

-- Índice opcional para filtrar/relatar por grupo
create index if not exists idx_profiles_grupo on public.profiles (grupo);

-- ──────────────────────────────────────────────────────────────
--  Observações de segurança (RLS)
--  A tela grava essas colunas via UPDATE em profiles feito pelo
--  admin logado. Isso depende de já existir uma policy de UPDATE
--  para administradores em public.profiles (o app já atualiza
--  status/role hoje, então a policy provavelmente já existe).
--  Se o UPDATE falhar por RLS, criar/ajustar a policy, ex.:
--
--    create policy "admin atualiza perfis"
--      on public.profiles for update
--      using  (exists (select 1 from public.profiles p
--                      where p.id = auth.uid() and p.role='admin'))
--      with check (true);
-- ──────────────────────────────────────────────────────────────
