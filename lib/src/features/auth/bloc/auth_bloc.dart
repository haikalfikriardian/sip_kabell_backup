import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthBloc() : super(AuthInitial()) {
    // === Login ===
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      print('LoginRequested: ${event.email}, ${event.password}');
      try {
        await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        print('Login success!');
        emit(AuthSuccess());
      } on FirebaseAuthException catch (e) {
        print('FirebaseAuthException during login: ${e.message}');
        emit(AuthFailure(e.message ?? 'Login gagal'));
      } catch (e) {
        print('Unknown error during login: $e');
        emit(AuthFailure(e.toString()));
      }
    });

    // === Sign Up ===
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      print('SignUpRequested: ${event.email}, ${event.password}, ${event.name}');
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        // Tambahkan nama ke profil pengguna
        await userCredential.user?.updateDisplayName(event.name);
        await userCredential.user?.reload(); // refresh data user
        print('Sign up success & displayName updated to: ${event.name}');

        emit(AuthSuccess());
      } on FirebaseAuthException catch (e) {
        print('FirebaseAuthException during sign up: ${e.message}');
        emit(AuthFailure(e.message ?? 'Gagal daftar'));
      } catch (e) {
        print('Unknown error during sign up: $e');
        emit(AuthFailure(e.toString()));
      }
    });
  }
}
