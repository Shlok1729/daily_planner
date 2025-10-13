import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// MINIMAL TEST - Does this work?
class TestAuthState {
  final supabase.User? user;

  const TestAuthState({this.user});
}

void main() {
  const state = TestAuthState();

  // This should work - let's see if it gives the same error
  if (state.user == null) {
    print('user is null');
  } else {
    print('user is not null: ${state.user!.id}');
  }
}