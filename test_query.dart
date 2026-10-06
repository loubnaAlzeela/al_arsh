import "package:supabase_flutter/supabase_flutter.dart";
import "dart:io";
import "package:flutter_dotenv/flutter_dotenv.dart";

void main() async {
  await dotenv.load(fileName: ".env");
  final client = SupabaseClient(
    dotenv.env["SUPABASE_URL"]!,
    dotenv.env["SUPABASE_ANON_KEY"]!,
  );
  try {
    final data = await client.from("posts_anonymous").select();
    print("Success: $data");
  } catch (e) {
    print("Error: $e");
  }
  exit(0);
}
