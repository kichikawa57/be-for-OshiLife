create table public.artists_groups (
  id uuid primary key,
  name text not null,
  furigana text,
  created_at TIMESTAMP DEFAULT now() not null,
  updated_at TIMESTAMP DEFAULT now() not null,
  deleted_at TIMESTAMP
);

create unique index idx_unique_name_in_artists_groups
  on artists_groups (name) 
  where deleted_at is null;

-- artists_groupsテーブルRLS設定
alter table public.artists_groups enable row level security;
  create policy "allow select for all authenticated users" on public.artists_groups for select using (auth.role() = 'authenticated');

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
  before update on public.artists_groups
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
  before delete on public.artists_groups
  for each row execute function logical_delete();
