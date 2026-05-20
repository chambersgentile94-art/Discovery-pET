-- Discovery-pET - Ensure one alert preference row per user

create unique index if not exists idx_alert_preferences_unique_user_id
on public.alert_preferences(user_id);
