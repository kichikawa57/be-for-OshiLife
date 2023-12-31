create table public.artists (
  id uuid primary key,
  group_id uuid references public.artists_groups(id) on delete cascade not null,
  name text not null,
  furigana text,
  created_at TIMESTAMP DEFAULT now() not null,
  updated_at TIMESTAMP DEFAULT now() not null,
  deleted_at TIMESTAMP
);

create unique index idx_unique_group_and_name_on_artists
  on artists (group_id, name) 
  where deleted_at is null;

-- artistsテーブルRLS設定
alter table public.artists enable row level security;
  create policy "allow select for all authenticated users" on public.artists for select using (auth.role() = 'authenticated');
create policy "allow insert for users themselves" on public.oshis for insert with check (true);
create policy "allow delete for users themselves" on public.oshis for delete using (true);

-- updated_atを更新する関数
create or replace function update_modified_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language 'plpgsql';

-- updated_atを更新するトリガー
create trigger on_artists_updated
  before update on public.artists
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
create trigger on_artists_logical_deleted
  before delete on public.artists
  for each row execute function logical_delete();
