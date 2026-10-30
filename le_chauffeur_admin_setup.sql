-- LE CHAUFFEUR : sécurisation de l'espace administrateur
-- À exécuter dans Supabase > SQL Editor APRÈS création du compte administrateur.
-- Remplace l'adresse ci-dessous par l'e-mail exact du compte créé dans Authentication > Users.

create table if not exists public.app_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.app_admins enable row level security;
alter table public.reservations enable row level security;

revoke all on public.app_admins from anon, authenticated;
grant select on public.app_admins to authenticated;

-- Un administrateur ne peut lire que sa propre inscription dans la liste des admins.
drop policy if exists "Admins can read own admin record" on public.app_admins;
create policy "Admins can read own admin record"
on public.app_admins for select to authenticated
using (user_id = auth.uid());

-- Les utilisateurs authentifiés qui ne figurent pas dans app_admins n'ont aucun droit sur les réservations.
revoke all on public.reservations from anon, authenticated;
grant insert (reservation_code, customer_name, customer_phone, ticket_type, quantity, payment_method, transfer_reference)
on public.reservations to anon;
grant select, update (status) on public.reservations to authenticated;

drop policy if exists "Public can submit pending reservations" on public.reservations;
create policy "Public can submit pending reservations"
on public.reservations for insert to anon
with check (status = 'pending');

drop policy if exists "Admins can view reservations" on public.reservations;
create policy "Admins can view reservations"
on public.reservations for select to authenticated
using (exists (select 1 from public.app_admins a where a.user_id = auth.uid()));

drop policy if exists "Admins can update reservation status" on public.reservations;
create policy "Admins can update reservation status"
on public.reservations for update to authenticated
using (exists (select 1 from public.app_admins a where a.user_id = auth.uid()))
with check (exists (select 1 from public.app_admins a where a.user_id = auth.uid()));

-- ÉTAPE FINALE : après avoir créé l'utilisateur dans Authentication > Users,
-- décommente la ligne ci-dessous et remplace l'adresse e-mail par la tienne :
-- insert into public.app_admins(user_id) select id from auth.users where email = 'TON-EMAIL@EXEMPLE.COM'
-- on conflict (user_id) do nothing;
