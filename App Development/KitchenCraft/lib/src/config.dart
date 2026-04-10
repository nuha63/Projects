// Helper to expose env-based configuration values.
// Ensure `dotenv.load()` has been called in `main()` before accessing these.
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Primary getter for the Gemini API key stored in the project's `.env` file.
/// Expected name in the file: `GEMINI_API_KEY`.
String? get geminiApiKey => dotenv.env['GEMINI_API_KEY'];

/// Primary getter for the Groq API key stored in the project's `.env` file.
/// Expected name in the file: `GROQ_API_KEY`.
String? get groqApiKey => dotenv.env['GROQ_API_KEY'];

/// Backwards-compatible alias used in some places.
String? get textGeminiApiKey => geminiApiKey;

/// Backend URL (for example, a Firebase Function or other API) used by the app.
/// Expected value in `.env`: BACKEND_URL=https://us-central1-.../YOUR_FUNCTION
String? get backendUrl => dotenv.env['BACKEND_URL'];
