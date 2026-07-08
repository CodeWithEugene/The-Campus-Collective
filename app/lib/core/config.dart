/// Build-time configuration for The Campus Collective.
///
/// The Supabase keys here are the *publishable/anon* key — designed to be public
/// and safe to embed. RLS restricts anon to reading distribution tables and
/// inserting anonymous feedback (see project.md §17). No user data ever leaves
/// the device.
class Config {
  static const String supabaseUrl = 'https://dhobuspndffvhemwcdnl.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_JBAj3YxBNTHAR8E7Dsh96Q_32FsgUpa';

  /// The on-device model. Default is the stock Gemma 4 E2B `.litertlm` — an
  /// ungated, verified-live URL, and the safe size for 6 GB phones. The
  /// fine-tuned `gemma-4-tcc` build swaps in via the Supabase model_manifest
  /// (no app update) once its on-device conversion is uploaded.
  static const String defaultModelName = 'Gemma 4 E2B';
  static const String defaultModelVersion = 'e2b-stock-1.0';
  static const int defaultModelSizeBytes = 2588147712; // exact E2B .litertlm size
  static const String defaultModelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

  /// Our fine-tuned Gemma 4 E4B (`gemma-4-tcc`), for 8 GB+ phones. Selected by
  /// the Supabase manifest per-device once `gemma_model/molab/tcc_convert.py`
  /// has produced + uploaded the on-device `.litertlm`.
  static const String tunedModelName = 'Gemma 4 TCC (E4B)';
  static const int tunedModelSizeBytes = 3865470566; // ~3.6 GB (E4B .litertlm)
  static const String tunedModelUrl =
      'https://huggingface.co/Eugeniuss/gemma-4-tcc-e4b-litertlm/resolve/main/model.litertlm';

  static const String appVersion = '1.0.0';
}
