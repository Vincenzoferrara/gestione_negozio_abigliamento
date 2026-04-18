import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'background_removal_controller.dart';
import 'background_removal_service.dart';

class BackgroundRemovalDesktopPage extends StatelessWidget {
  const BackgroundRemovalDesktopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BackgroundRemovalController>(
      create: (_) => BackgroundRemovalController(
        service: const BackgroundRemovalService(),
      ),
      child: const _BackgroundRemovalDesktopView(),
    );
  }
}

class _BackgroundRemovalDesktopView extends StatelessWidget {
  const _BackgroundRemovalDesktopView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackgroundRemovalController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Desktop Background Remover (CLI)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildInputCard(context, vm),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOutputCard(context, vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(BuildContext context, BackgroundRemovalController vm) {
    final running = vm.status == BackgroundUiStatus.running;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1) Selezione input', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: running ? null : () => vm.pickInputImage(),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Seleziona immagine'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: running ? null : () => vm.process(),
                  icon: running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(running ? 'Elaborazione...' : '2) Esegui rimozione'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Input: ${vm.inputPath ?? '-'}', maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            if (vm.inputPath != null)
              Expanded(
                child: Container(
                  color: Colors.black12,
                  child: Image.file(
                    File(vm.inputPath!),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(child: Text('Anteprima non disponibile')),
                  ),
                ),
              )
            else
              const Expanded(child: Center(child: Text('Nessun input selezionato'))),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputCard(BuildContext context, BackgroundRemovalController vm) {
    final done = vm.status == BackgroundUiStatus.done && vm.outputBytes != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('3) Output e salvataggio', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: done ? () => vm.saveOutputAsPng() : null,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('4) Salva PNG'),
                ),
                const SizedBox(width: 8),
                if (vm.elapsed != null)
                  Text('Tempo: ${vm.elapsed!.inMilliseconds} ms'),
              ],
            ),
            const SizedBox(height: 8),
            if (vm.error != null)
              Text('Errore: ${vm.error}', style: const TextStyle(color: Colors.red)),
            if (vm.stderrText.isNotEmpty)
              Text('stderr: ${vm.stderrText}', maxLines: 3, overflow: TextOverflow.ellipsis),
            if (vm.stdoutText.isNotEmpty)
              Text('stdout: ${vm.stdoutText}', maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Expanded(
              child: vm.outputBytes == null
                  ? const Center(child: Text('Nessun output disponibile'))
                  : Container(
                      color: Colors.black12,
                      child: Image.memory(
                        vm.outputBytes!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(child: Text('Preview output non disponibile')),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
