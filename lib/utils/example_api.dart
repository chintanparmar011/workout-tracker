/// Central configuration for external APIs used by FitTrack.
///
/// Both ExerciseDB and USDA FoodData Central APIs support live fetching
/// when valid API keys are configured, and gracefully fall back to curated
/// local databases when offline or when keys are omitted.
class ApiConstants {
  // --- ExerciseDB API (RapidAPI) ---
  /// RapidAPI Key for ExerciseDB (e.g. from rapidapi.com/justin-WFoydavuJ/api/exercisedb)
  /// If empty or rate-limited, FitTrack automatically falls back to curated built-in exercises.
  static const String exerciseDbApiKey = 'your exercisedb api';
  static const String exerciseDbHost = 'exercisedb.p.rapidapi.com';
  static const String exerciseDbBaseUrl = 'https://exercisedb.p.rapidapi.com';

  // --- USDA FoodData Central API ---
  /// Free API key from https://api.data.gov/signup/ or use 'DEMO_KEY' (rate-limited).
  /// If empty or exhausted, FitTrack automatically falls back to curated common fitness foods.
  static const String usdaApiKey = 'your usda api';
  static const String usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
}
