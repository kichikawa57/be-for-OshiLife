ALTER TABLE public.artists ADD group_id UUID REFERENCES public.artists_groups(id) ON DELETE CASCADE NOT NULL;
