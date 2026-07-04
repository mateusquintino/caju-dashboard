-- ══════════════════════════════════════════════════════════════
--  Migração 05 — Login Google + trava de domínio @cajupar.com
--
--  Ajusta o gatilho handle_new_user para:
--   1. REJEITAR qualquer cadastro cujo e-mail não seja @cajupar.com
--      (vale para login Google E cadastro por e-mail).
--   2. Continuar criando o perfil com status 'pending' → o acesso só
--      é liberado após aprovação de um admin (fluxo já existente).
--   3. Pegar o nome vindo do Google (full_name / name), além de 'nome'.
--
--  Já aplicada no projeto via MCP. Mantida aqui para versionamento.
--  IMPORTANTE (fora do SQL): habilitar o provedor Google em
--  Supabase → Authentication → Providers, e adicionar a URL do
--  dashboard em Authentication → URL Configuration.
-- ══════════════════════════════════════════════════════════════

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  if lower(split_part(new.email, '@', 2)) <> 'cajupar.com' then
    raise exception 'Apenas e-mails @cajupar.com podem criar conta';
  end if;

  insert into public.profiles (id, email, nome, role, status)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'nome',
             new.raw_user_meta_data->>'full_name',
             new.raw_user_meta_data->>'name',
             split_part(new.email, '@', 1)),
    'user',
    'pending'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
