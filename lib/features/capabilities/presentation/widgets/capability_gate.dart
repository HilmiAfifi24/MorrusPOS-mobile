import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/capability_bloc.dart';

class CapabilityGate extends StatelessWidget {
  final List<String> requiredCapabilities;
  final Widget child;

  const CapabilityGate({
    super.key,
    required this.requiredCapabilities,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CapabilityBloc, CapabilityState>(
      builder: (context, state) {
        if (state is CapabilityLoaded) {
          if (requiredCapabilities.every(state.has)) return child;
          return const _CapabilityMessage(
            title: 'Fitur belum aktif',
            message: 'Fitur ini belum diaktifkan untuk outlet yang dipilih.',
          );
        }
        if (state is CapabilityFailure) {
          return _CapabilityMessage(
            title: 'Gagal memuat akses fitur',
            message: state.message,
            onRetry: () => _reload(context),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  static void _reload(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is Authenticated && auth.selectedOutletId?.isNotEmpty == true) {
      context.read<CapabilityBloc>().add(
        LoadCapabilities(auth.selectedOutletId!),
      );
    }
  }
}

class _CapabilityMessage extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _CapabilityMessage({
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MorrusPOS')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
