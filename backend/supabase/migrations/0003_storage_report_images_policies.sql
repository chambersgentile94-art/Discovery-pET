-- Discovery-pET - Storage policies for report images
-- Bucket expected: report-images

insert into storage.buckets (id, name, public)
values ('report-images', 'report-images', true)
on conflict (id) do update set public = true;

-- Allow authenticated users to upload report images.
-- The app stores files under: {report_id}/{timestamp}.{extension}
create policy "Authenticated users can upload report images"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'report-images'
);

-- Allow public read access to images from this bucket.
-- This is useful because the app stores public image URLs in report_images.image_url.
create policy "Anyone can read report images"
on storage.objects
for select
to public
using (
  bucket_id = 'report-images'
);

-- Allow authenticated users to update objects in this bucket if needed later.
create policy "Authenticated users can update report images"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'report-images'
)
with check (
  bucket_id = 'report-images'
);

-- Allow authenticated users to delete objects in this bucket if needed later.
create policy "Authenticated users can delete report images"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'report-images'
);
