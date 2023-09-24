create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text not null,
  name text not null,
  age varchar(10) not null,
  created_at TIMESTAMP DEFAULT now() not null,
  updated_at TIMESTAMP DEFAULT now() not null,
  deleted_at TIMESTAMP
);

-- profilesテーブルRLS設定
alter table profiles enable row level security;
create policy "allow select for all authenticated users" on public.profiles for select using (auth.role() = 'authenticated');
create policy "allow update for users themselves" on public.profiles for update using (auth.uid() = id);

-- ユーザー作成時に一緒にprofilesも作成する関数
create or replace function public.add_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, age)
  values (new.id, new.email,
  new.raw_user_meta_data->>'name',
  new.raw_user_meta_data->>'age');
  return new;
end;
$$;

-- ユーザー作成時に一緒にprofilesも作成するトリガー
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.add_user();

-- updated_atを更新する関数
create or replace function update_modified_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language 'plpgsql';

-- updated_atを更新するトリガー
create trigger on_profiles_updated
  before update on public.profiles
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
create trigger on_profiles_logical_deleted
  before delete on public.profiles
  for each row execute function logical_delete();