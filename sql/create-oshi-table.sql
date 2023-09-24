create table public.oshis (
  id uuid primary key,
  user_id uuid references auth.users(id) on delete cascade,
  artist_id uuid references public.artists(id) on delete cascade,
  image_url text,
  memo text,
  color varchar(10) not null,
  is_edit_color boolean not null,
  created_at TIMESTAMP DEFAULT now() not null,
  updated_at TIMESTAMP DEFAULT now() not null,
  deleted_at TIMESTAMP
);

-- oshisテーブルRLS設定
alter table oshis enable row level security;
create policy "allow select for all authenticated users" on public.oshis for select using (auth.role() = 'authenticated');
create policy "allow update for users themselves" on public.oshis for update using (auth.uid() = user_id);

-- updated_atを更新する関数
create or replace function update_modified_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language 'plpgsql';

-- updated_atを更新するトリガー
create trigger on_oshis_updated
  before update on public.oshis
  for each row execute function update_modified_column();

-- deleted_atを更新する関数
create or replace function logical_delete()
returns trigger as $$
begin
  new.deleted_at = now();
  return new;
end;
$$ language 'plpgsql';

-- deleted_atを更新するトリガー
create trigger on_oshis_logical_deleted
  before delete on public.oshis
  for each row execute function logical_delete();

-- oshis用のstorage
insert into storage.buckets (id, name) values ('oshis', 'oshis');

create policy "Public Access"
  on storage.objects for select
  using ( bucket_id = 'public' );