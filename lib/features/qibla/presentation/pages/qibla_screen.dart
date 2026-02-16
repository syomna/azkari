import 'package:azkar_app/di/injection_container.dart';
import 'package:azkar_app/features/qibla/presentation/providers/qibla_provider.dart';
import 'package:azkar_app/features/qibla/presentation/widgets/qibla_body.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // GetIt provides the instance with all dependencies (UseCase/Repo) injected
      create: (context) => sl<QiblaProvider>()..init(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('القبلة',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Consumer<QiblaProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return Center(child: Text(provider.errorMessage!));
            }

            return QiblaBody(
              heading: provider.currentHeading,
              difference: provider.difference,
              isAligned: provider.isAligned,
            );
          },
        ),
      ),
    );
  }
}
