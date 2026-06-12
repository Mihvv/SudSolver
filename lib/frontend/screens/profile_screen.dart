import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/providers/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Błąd ładowania profilu'),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Niezalogowany'),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: 40 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  if (user.photoUrl != null)
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(user.photoUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 60,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Dane użytkownika
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField('Nazwa', user.displayName ?? 'Brak'),
                          const SizedBox(height: 12),
                          _buildField('Email', user.email ?? 'Brak'),
                          const SizedBox(height: 12),
                          _buildField('ID użytkownika', user.uid),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Przycisk wylogowania
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).signOut();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Wyloguj się'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}