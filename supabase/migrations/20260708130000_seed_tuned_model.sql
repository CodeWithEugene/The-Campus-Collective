-- Fine-tuned gemma-4-tcc E4B on-device build (int4 .litertlm, ungated).
-- Channel 'beta' until validated on a physical 8 GB+ Android — the app's
-- stable channel keeps serving stock E2B; flip channel to promote.

insert into public.model_manifest
  (name, variant, version, url, size_bytes, sha256, min_app_version, channel, is_active)
values
  ('Gemma 4 TCC (E4B)', 'e4b-tcc', 'e4b-tcc-1.0',
   'https://huggingface.co/Eugeniuss/gemma-4-tcc-e4b-litertlm/resolve/main/model.litertlm',
   4257631456,
   'a26edeb44f29e4a584af22670c0efb7609a9d9e21dc2513cc70212036b3a3164',
   '1.0.0', 'beta', true)
on conflict (variant, version) do nothing;
