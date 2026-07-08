-- Seed the distribution tables (idempotent).
-- Model: stock Gemma 4 E2B .litertlm (ungated litert-community mirror) — the
-- app's shipping default. The fine-tuned e4b-tcc row is added once
-- gemma_model/molab/tcc_convert.py has produced + uploaded its .litertlm.

insert into public.model_manifest
  (name, variant, version, url, size_bytes, sha256, min_app_version, channel, is_active)
values
  ('Gemma 4 E2B', 'e2b-base', 'e2b-stock-1.0',
   'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
   2588147712,
   '181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c',
   '1.0.0', 'stable', true)
on conflict (variant, version) do nothing;

insert into public.content_packs (kind, version, storage_path, sha256, size_bytes, notes)
values
  ('corpus', 1, 'corpus_v1.json',
   'df07c37f0ffbb5c268f98ec0fb8459465b4f42944e99be5457637a77e62d24ba', 2063,
   'Starter UoEm facts corpus for RAG grounding'),
  ('kiembu_phrasebook', 1, 'kiembu_phrasebook.json',
   'baff895fb0784c7865fa9a546ae48e65faf62b385424be737041607783fa83f3', 816,
   'Hand-collected Kiembu greetings/phrases'),
  ('matatu_fares', 1, 'matatu_fares.json',
   '550384f33e971b1d586e23c470aed66cc13580b3196060b0ceb9fa33525201c8', 835,
   'Embu-area matatu fare estimates (sample data, labeled in-app)'),
  ('mpesa_tariffs', 1, 'mpesa_tariffs.json',
   '9d2dee289fce5d60d6d77b3f8416656139f746d218a1f753b88780a2cc87f5d2', 1402,
   'Public Safaricom tariff table'),
  ('safety_contacts', 1, 'safety_contacts.json',
   '97c8056909fa29221cc83e049cfc8536340c77e18c4bf9b1beecae8e0488b018', 1372,
   'Campus + national emergency contacts')
on conflict (kind, version) do nothing;
