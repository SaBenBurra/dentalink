-- load_test_seed.sql'in eklediklerini siler; sayaçları reconcile düzeltir.
begin;
delete from public.messages where content like '[seed] %';
delete from public.posts where title like '[seed] %';
select public.reconcile_counters();
commit;
