-- Keep repair brand display names visually consistent.
update public.repair_prices
set brand = case brand
  when 'HONOR' then 'Honor'
  when 'OPPO' then 'Oppo'
  else brand
end
where brand in ('HONOR','OPPO');
