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

  /// The on-device model. Points at OUR fine-tuned Gemma 4 E4B (`gemma-4-tcc`),
  /// hosted ungated on Hugging Face (Apache-2.0) so first-run download needs no
  /// login. Overridden at runtime by the Supabase model_manifest when online.
  static const String defaultModelName = 'Gemma 4 TCC (E4B)';
  static const String defaultModelVersion = 'e4b-tcc-1.0';
  static const int defaultModelSizeBytes = 3865470566; // ~3.6 GB (E4B .litertlm)
  static const String defaultModelUrl =
      'https://huggingface.co/Eugeniuss/gemma-4-tcc-e4b-litertlm/resolve/main/model.litertlm';

  /// Fallback: stock E2B (~2.6 GB) for 6 GB phones or if the fine-tuned model
  /// isn't converted yet. The Supabase manifest can select this per-device.
  static const String fallbackModelName = 'Gemma 4 E2B';
  static const int fallbackModelSizeBytes = 2684354560;
  static const String fallbackModelUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

  static const String appVersion = '1.0.0';
}
