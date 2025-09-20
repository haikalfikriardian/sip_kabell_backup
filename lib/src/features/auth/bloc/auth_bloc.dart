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
      try {
        await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        emit(AuthSuccess());
      } on FirebaseAuthException catch (e) {
        String message = 'Email atau password salah';

        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          message = 'Email atau password salah';
        } else if (e.code == 'invalid-email') {
          message = 'Format email tidak valid';
        } else if (e.code == 'too-many-requests') {
          message = 'Terlalu banyak percobaan login. Coba beberapa saat lagi.';
        }

        emit(AuthFailure(message));
      } catch (e) {
        emit(AuthFailure('Terjadi kesalahan saat login'));
      }
    });

    // === Sign Up ===
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        // Tambahkan nama ke profil pengguna
        await userCredential.user?.updateDisplayName(event.name);
        await userCredential.user?.reload(); // refresh data user

        emit(AuthSuccess());
      } on FirebaseAuthException catch (e) {
        String message = 'Gagal daftar';
        if (e.code == 'email-already-in-use') {
          message = 'Email sudah digunakan';
        } else if (e.code == 'weak-password') {
          message = 'Password terlalu lemah';
        } else if (e.code == 'invalid-email') {
          message = 'Format email tidak valid';
        }

        emit(AuthFailure(message));
      } catch (e) {
        emit(AuthFailure('Terjadi kesalahan saat daftar'));
      }
    });
  }
}
