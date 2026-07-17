-- 体育プラン｜提出テーブル
-- Supabase の SQL Editor に貼って Run するだけ。1回だけ実行すればよい。
--
-- 設計の考え方：
--   anon キーは index.html に書く＝誰でも見られる。
--   なので anon には INSERT だけを許し、SELECT は許さない。
--   これでキーを見た人でも他の生徒の記録を読めない。
--   先生は Supabase の画面（service_role でRLSを迂回）で見る。
--   将来「先生用ページ」を作るときは、先生がログインすれば
--   authenticated ポリシーで読めるようにしてある。

create table if not exists public.submissions (
  id           uuid primary key default gen_random_uuid(),
  submitted_at timestamptz not null default now(),
  day          date        not null,                       -- 授業の日（端末のローカル日付）
  name         text        not null check (char_length(name) between 1 and 30),
  sport        text                 check (sport is null or char_length(sport) <= 40),
  menu         jsonb       not null,                       -- 練習の配列（アプリのmenuそのまま）
  note         text                 check (note is null or char_length(note) <= 2000),
  total_min    int                  check (total_min is null or total_min between 0 and 600),
  item_count   int                  check (item_count is null or item_count between 0 and 100)
);

comment on table public.submissions is '生徒が提出した練習メニュー。anonはINSERTのみ。';

create index if not exists submissions_day_idx  on public.submissions (day desc);
create index if not exists submissions_name_idx on public.submissions (name);

alter table public.submissions enable row level security;

-- 生徒（anon）：提出だけできる。読めない・消せない・直せない
drop policy if exists "anon can insert" on public.submissions;
create policy "anon can insert"
  on public.submissions for insert
  to anon
  with check (true);

-- 先生（ログイン済み）：読める。先生用ページを作るときに効く
drop policy if exists "authenticated can select" on public.submissions;
create policy "authenticated can select"
  on public.submissions for select
  to authenticated
  using (true);
