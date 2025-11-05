import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'theme_settings.dart';

/// GUI per le impostazioni del tema
class ThemeSettingsTab extends StatelessWidget {
  const ThemeSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeSettings>(
      builder: (context, themeSettings, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Impostazioni Tema',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      inherit: true,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personalizza l\'aspetto dell\'applicazione',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      inherit: true,
                    ),
              ),
              const SizedBox(height: 32),

              // Sezione Modalità Tema
              _buildSection(
                context,
                title: 'Modalità Tema',
                child: _buildThemeModeSelector(context, themeSettings),
              ),

              const SizedBox(height: 32),

              // Sezione Colore Primario
              _buildSection(
                context,
                title: 'Colore Primario',
                child: Column(
                  children: [
                    _buildColorPicker(
                      context,
                      'Colore Primario',
                      themeSettings.primaryColor,
                      (color) => themeSettings.setPrimaryColor(color),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => themeSettings.resetColor(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Ripristina Colore Predefinito'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Sezione Interfaccia
              _buildSection(
                context,
                title: 'Interfaccia',
                child: _buildInterfaceSettings(context, themeSettings),
              ),

              const SizedBox(height: 32),

              // Sezione Anteprima
              _buildSection(
                context,
                title: 'Anteprima',
                child: _buildPreview(context, themeSettings),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required Widget child}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    inherit: true,
                  ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeSelector(BuildContext context, ThemeSettings themeSettings) {
    return Column(
      children: [
        _buildThemeModeOption(
          context,
          themeSettings,
          'Chiaro',
          'Usa sempre il tema chiaro',
          Icons.wb_sunny,
          ThemeMode.light,
        ),
        const SizedBox(height: 12),
        _buildThemeModeOption(
          context,
          themeSettings,
          'Scuro',
          'Usa sempre il tema scuro',
          Icons.nightlight_round,
          ThemeMode.dark,
        ),
        const SizedBox(height: 12),
        _buildThemeModeOption(
          context,
          themeSettings,
          'Sistema',
          'Segui le impostazioni del sistema',
          Icons.settings_system_daydream,
          ThemeMode.system,
        ),
      ],
    );
  }

  Widget _buildThemeModeOption(
    BuildContext context,
    ThemeSettings themeSettings,
    String title,
    String subtitle,
    IconData icon,
    ThemeMode mode,
  ) {
    final isSelected = themeSettings.themeMode == mode;

    return InkWell(
      onTap: () => themeSettings.setThemeMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? themeSettings.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? themeSettings.primaryColor.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? themeSettings.primaryColor : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? themeSettings.primaryColor
                              : null,
                          inherit: true,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          inherit: true,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: themeSettings.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(
    BuildContext context,
    String label,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    return InkWell(
      onTap: () => _showColorPickerDialog(context, currentColor, onColorChanged),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          inherit: true,
                        ),
                  ),
                  Text(
                    '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                          inherit: true,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.color_lens),
          ],
        ),
      ),
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    Color pickerColor = currentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona Colore'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Material Color Picker
              MaterialPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) {
                  pickerColor = color;
                },
                enableLabel: true,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Block Color Picker
              BlockPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) {
                  pickerColor = color;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(pickerColor);
              Navigator.of(context).pop();
            },
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceSettings(BuildContext context, ThemeSettings themeSettings) {
    return Column(
      children: [
        SwitchListTile(
          value: themeSettings.showHomeReport,
          onChanged: (value) => themeSettings.setShowHomeReport(value),
          title: const Text('Mostra Report nella Home'),
          subtitle: const Text('Visualizza le statistiche nella pagina principale'),
          secondary: Icon(
            Icons.assessment,
            color: themeSettings.primaryColor,
          ),
          activeColor: themeSettings.primaryColor,
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context, ThemeSettings themeSettings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anteprima dei componenti con i colori selezionati',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                inherit: true,
              ),
        ),
        const SizedBox(height: 16),

        // Preview buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check),
              label: const Text('Elevated Button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeSettings.primaryColor,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.favorite_border),
              label: const Text('Outlined Button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: themeSettings.primaryColor,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.info_outline),
              label: const Text('Text Button'),
              style: TextButton.styleFrom(
                foregroundColor: themeSettings.primaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Preview card
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: themeSettings.primaryColor,
              child: const Icon(Icons.store, color: Colors.white),
            ),
            title: Text(
              'Card Preview',
              style: TextStyle(color: themeSettings.primaryColor),
            ),
            subtitle: const Text('Questo è un esempio di card'),
            trailing: Icon(Icons.arrow_forward, color: themeSettings.primaryColor),
          ),
        ),
      ],
    );
  }
}
