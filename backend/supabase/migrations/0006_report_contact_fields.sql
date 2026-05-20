-- Discovery-pET - Optional contact fields for animal reports

alter table public.animal_reports
  add column if not exists contact_phone text,
  add column if not exists show_contact_phone boolean not null default false;
