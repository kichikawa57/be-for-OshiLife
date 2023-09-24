create table public.schedules (
  id uuid primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  oshi_id uuid references public.oshis(id) on delete cascade,
  title text,
  memo text,
  start_at TIMESTAMP DEFAULT now() not null,
  end_at TIMESTAMP DEFAULT now() not null,
  is_public boolean not null,
  created_at TIMESTAMP DEFAULT now() not null,
  updated_at TIMESTAMP DEFAULT now() not null,
  deleted_at TIMESTAMP
);

-- schedulesテーブルRLS設定
alter table public.schedules enable row level security;
create policy "allow select for all authenticated users" on public.schedules for select using (auth.role() = 'authenticated');
create policy "allow update for users themselves" on public.schedules for update using (auth.uid() = user_id);

-- updated_atを更新する関数
create or replace function update_modified_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language 'plpgsql';

-- updated_atを更新するトリガー
create trigger on_schedules_updated
  before update on public.schedules
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
create trigger on_schedules_logical_deleted
  before delete on public.schedules
  for each row execute function logical_delete();
