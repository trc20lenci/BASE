-- =============================================================================
-- BASE — SQL-схема Supabase (PostgreSQL)
-- =============================================================================
-- Выполнить целиком в Supabase Dashboard → SQL Editor → New query,
-- либо через Supabase CLI: `supabase db push` (если файл лежит в
-- supabase/migrations/).
--
-- Соответствие таблиц слоям приложения:
--   profiles           -> features/auth, features/profile
--   projects            -> features/project
--   project_timelines   -> features/editor (таймлайн: клипы + текст)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. profiles — профиль пользователя (username, avatar_url)
-- -----------------------------------------------------------------------------
-- id ссылается на auth.users.id (управляется Supabase Auth). Email НЕ
-- дублируется здесь — он уже есть в auth.users, доступен через сессию.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null default '',
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Пользователь видит и меняет только свой профиль. Также разрешаем всем
-- авторизованным читать чужие профили (нужно, если в будущем понадобится
-- показывать, например, автора проекта в совместной работе) — на этом
-- этапе MVP такого сценария нет, поэтому оставляем select только "себя".
create policy "profiles: select own" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles: insert own" on public.profiles
  for insert with check (auth.uid() = id);

create policy "profiles: update own" on public.profiles
  for update using (auth.uid() = id);

-- -----------------------------------------------------------------------------
-- 2. projects — метаданные проекта монтажа
-- -----------------------------------------------------------------------------

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  title text not null default 'Новый проект',
  format text not null default '9:16'
    check (format in ('16:9', '9:16', '1:1', '4:5')),
  thumbnail_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists projects_owner_id_updated_at_idx
  on public.projects (owner_id, updated_at desc);

alter table public.projects enable row level security;

create policy "projects: select own" on public.projects
  for select using (auth.uid() = owner_id);

create policy "projects: insert own" on public.projects
  for insert with check (auth.uid() = owner_id);

create policy "projects: update own" on public.projects
  for update using (auth.uid() = owner_id);

create policy "projects: delete own" on public.projects
  for delete using (auth.uid() = owner_id);

-- Обязательно для Supabase Realtime (используется watchUserProjects
-- через .stream() в ProjectRemoteDataSource) — таблица должна быть
-- добавлена в публикацию supabase_realtime.
alter publication supabase_realtime add table public.projects;

-- -----------------------------------------------------------------------------
-- 3. project_timelines — содержимое монтажа (клипы + текстовые слои)
-- -----------------------------------------------------------------------------
-- Отдельная таблица от projects (см. комментарий в
-- TimelineRemoteDataSource) — список проектов не должен подтягивать
-- потенциально большой JSON с содержимым таймлайна.

create table if not exists public.project_timelines (
  project_id uuid primary key references public.projects (id) on delete cascade,
  clips jsonb not null default '[]'::jsonb,
  text_overlays jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.project_timelines enable row level security;

-- Доступ к таймлайну определяется владением связанного проекта.
create policy "project_timelines: select via project ownership" on public.project_timelines
  for select using (
    exists (
      select 1 from public.projects p
      where p.id = project_timelines.project_id and p.owner_id = auth.uid()
    )
  );

create policy "project_timelines: insert via project ownership" on public.project_timelines
  for insert with check (
    exists (
      select 1 from public.projects p
      where p.id = project_timelines.project_id and p.owner_id = auth.uid()
    )
  );

create policy "project_timelines: update via project ownership" on public.project_timelines
  for update using (
    exists (
      select 1 from public.projects p
      where p.id = project_timelines.project_id and p.owner_id = auth.uid()
    )
  );

-- -----------------------------------------------------------------------------
-- 4. Storage — бакеты
-- -----------------------------------------------------------------------------
-- Все три бакета создаются публичными (public = true), что соответствует
-- модели Firebase Storage по умолчанию: файл доступен по прямому URL без
-- дополнительной авторизации запроса, но путь непредсказуем
-- (userId/projectId/clipId), поэтому неавторизованный доступ требует
-- знания точного пути. Для более строгой приватности переключите бакет
-- на private и используйте createSignedUrl() вместо getPublicUrl()
-- в соответствующих datasource-файлах.

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('project-media', 'project-media', true),
  ('exports', 'exports', true)
on conflict (id) do nothing;

-- avatars: путь = {userId}.jpg — пользователь пишет только в свой файл.
create policy "avatars: public read" on storage.objects
  for select using (bucket_id = 'avatars');

create policy "avatars: owner write" on storage.objects
  for insert with check (
    bucket_id = 'avatars' and (storage.filename(name)) like auth.uid()::text || '.%'
  );

create policy "avatars: owner update" on storage.objects
  for update using (
    bucket_id = 'avatars' and (storage.filename(name)) like auth.uid()::text || '.%'
  );

-- project-media: путь = {ownerId}/{projectId}/{clipId}.ext
create policy "project-media: public read" on storage.objects
  for select using (bucket_id = 'project-media');

create policy "project-media: owner write" on storage.objects
  for insert with check (
    bucket_id = 'project-media' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "project-media: owner update" on storage.objects
  for update using (
    bucket_id = 'project-media' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "project-media: owner delete" on storage.objects
  for delete using (
    bucket_id = 'project-media' and (storage.foldername(name))[1] = auth.uid()::text
  );

-- exports: путь = {ownerId}/{projectId}.mp4 (зарезервировано для этапа,
-- когда рендер видео будет происходить на сервере/через Edge Function;
-- пока экспорт сохраняется локально на устройство через пакет `gal`,
-- см. README раздел "Экспорт видео").
create policy "exports: owner read" on storage.objects
  for select using (
    bucket_id = 'exports' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "exports: owner write" on storage.objects
  for insert with check (
    bucket_id = 'exports' and (storage.foldername(name))[1] = auth.uid()::text
  );

-- -----------------------------------------------------------------------------
-- 5. Автосоздание профиля при регистрации (доп. подстраховка)
-- -----------------------------------------------------------------------------
-- AuthRemoteDataSource.signUp уже создаёт строку в profiles явно из
-- клиента сразу после auth.signUp(). Триггер ниже — защитная сетка на
-- случай, если по какой-то причине клиентская вставка не выполнится
-- (например, разрыв сети между двумя запросами): гарантирует, что
-- профиль всё равно будет создан с пустым username, который пользователь
-- сможет заполнить позже.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (new.id, '', null)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
