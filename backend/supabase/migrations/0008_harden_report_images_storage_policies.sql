-- Discovery-pET - Harden Storage policies for report images

-- Keep public read access, but restrict update/delete to the owner of the linked report.
drop policy if exists "Authenticated users can update report images" on storage.objects;
drop policy if exists "Authenticated users can delete report images" on storage.objects;
drop policy if exists "Users can update own report images" on storage.objects;
drop policy if exists "Users can delete own report images" on storage.objects;

create policy "Users can update own report images"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'report-images'
  and exists (
    select 1
    from public.report_images ri
    join public.animal_reports ar on ar.id = ri.report_id
    where ri.storage_path = storage.objects.name
      and ar.created_by = auth.uid()
  )
)
with check (
  bucket_id = 'report-images'
  and exists (
    select 1
    from public.report_images ri
    join public.animal_reports ar on ar.id = ri.report_id
    where ri.storage_path = storage.objects.name
      and ar.created_by = auth.uid()
  )
);

create policy "Users can delete own report images"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'report-images'
  and exists (
    select 1
    from public.report_images ri
    join public.animal_reports ar on ar.id = ri.report_id
    where ri.storage_path = storage.objects.name
      and ar.created_by = auth.uid()
  )
);
