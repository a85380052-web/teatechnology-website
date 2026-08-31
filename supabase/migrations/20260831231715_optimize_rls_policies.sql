drop policy if exists admin_users_self_read on public.admin_users;
drop policy if exists admin_users_admin_delete on public.admin_users;
create policy admin_users_self_read on public.admin_users for select to authenticated using (user_id = (select auth.uid()));
create policy admin_users_admin_delete on public.admin_users for delete to authenticated using (private.is_admin() and user_id <> (select auth.uid()));

drop policy if exists hours_admin_read on public.business_hours;
drop policy if exists hours_admin_write on public.business_hours;
drop policy if exists hours_authenticated_read on public.business_hours;
drop policy if exists hours_public_read on public.business_hours;
create policy hours_public_read on public.business_hours for select to anon using (published = true);
create policy hours_authenticated_read on public.business_hours for select to authenticated using ((published = true) or private.is_admin());
create policy hours_admin_insert on public.business_hours for insert to authenticated with check (private.is_admin());
create policy hours_admin_update on public.business_hours for update to authenticated using (private.is_admin()) with check (private.is_admin());
create policy hours_admin_delete on public.business_hours for delete to authenticated using (private.is_admin());

drop policy if exists faqs_admin_read on public.faqs;
drop policy if exists faqs_admin_write on public.faqs;
drop policy if exists faqs_authenticated_read on public.faqs;
drop policy if exists faqs_public_read on public.faqs;
create policy faqs_public_read on public.faqs for select to anon using (active = true);
create policy faqs_authenticated_read on public.faqs for select to authenticated using ((active = true) or private.is_admin());
create policy faqs_admin_insert on public.faqs for insert to authenticated with check (private.is_admin());
create policy faqs_admin_update on public.faqs for update to authenticated using (private.is_admin()) with check (private.is_admin());
create policy faqs_admin_delete on public.faqs for delete to authenticated using (private.is_admin());

drop policy if exists media_admin_read on public.media_assets;
drop policy if exists media_admin_write on public.media_assets;
drop policy if exists media_authenticated_read on public.media_assets;
drop policy if exists media_public_read on public.media_assets;
create policy media_public_read on public.media_assets for select to anon using (active = true);
create policy media_authenticated_read on public.media_assets for select to authenticated using ((active = true) or private.is_admin());
create policy media_admin_insert on public.media_assets for insert to authenticated with check (private.is_admin());
create policy media_admin_update on public.media_assets for update to authenticated using (private.is_admin()) with check (private.is_admin());
create policy media_admin_delete on public.media_assets for delete to authenticated using (private.is_admin());

drop policy if exists repair_prices_admin_write on public.repair_prices;
drop policy if exists repair_prices_authenticated_read on public.repair_prices;
drop policy if exists repair_prices_public_read on public.repair_prices;
create policy repair_prices_public_read on public.repair_prices for select to anon using (active = true);
create policy repair_prices_authenticated_read on public.repair_prices for select to authenticated using ((active = true) or private.is_admin());
create policy repair_prices_admin_insert on public.repair_prices for insert to authenticated with check (private.is_admin());
create policy repair_prices_admin_update on public.repair_prices for update to authenticated using (private.is_admin()) with check (private.is_admin());
create policy repair_prices_admin_delete on public.repair_prices for delete to authenticated using (private.is_admin());

drop policy if exists services_admin_read on public.services;
drop policy if exists services_admin_write on public.services;
drop policy if exists services_authenticated_read on public.services;
drop policy if exists services_public_read on public.services;
create policy services_public_read on public.services for select to anon using (active = true);
create policy services_authenticated_read on public.services for select to authenticated using ((active = true) or private.is_admin());
create policy services_admin_insert on public.services for insert to authenticated with check (private.is_admin());
create policy services_admin_update on public.services for update to authenticated using (private.is_admin()) with check (private.is_admin());
create policy services_admin_delete on public.services for delete to authenticated using (private.is_admin());

drop policy if exists site_settings_admin_write on public.site_settings;
create policy site_settings_admin_insert on public.site_settings for insert to authenticated with check (private.is_admin());
create policy site_settings_admin_update on public.site_settings for update to authenticated using (private.is_admin()) with check (private.is_admin());
create policy site_settings_admin_delete on public.site_settings for delete to authenticated using (private.is_admin());
