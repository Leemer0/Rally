-- Supabase's optional automatic-RLS project helper is an event-trigger
-- implementation detail, not an application RPC. Some hosted projects grant
-- EXECUTE on it through the public role, which exposes the SECURITY DEFINER
-- function through the Data API. Keep the migration portable to local stacks
-- where the helper does not exist.
do $block$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    execute 'revoke all on function public.rls_auto_enable() from public';
    execute 'revoke all on function public.rls_auto_enable() from anon';
    execute 'revoke all on function public.rls_auto_enable() from authenticated';
  end if;
end
$block$;
