import 'package:flutter/material.dart';

class SearchableCheckboxDialog extends StatefulWidget {
  final String title;
  final String inputLabel;
  final List<String> input_list;
  final List<String> preselected_list;

  const SearchableCheckboxDialog({
    super.key,
    required this.title,
    required this.inputLabel,
    required this.input_list,
    required this.preselected_list,
  });

  static Future<List<String>?> show(
    BuildContext context, {
    required String title,
    required String inputLabel,
    required List<String> input_list,
    required List<String> preselected_list,
  }) {
    return showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => SearchableCheckboxDialog(
        title: title,
        inputLabel: inputLabel,
        input_list: input_list,
        preselected_list: preselected_list,
      ),
    );
  }

  @override
  State<SearchableCheckboxDialog> createState() =>
      _SearchableCheckboxDialogState();
}

class _SearchableCheckboxDialogState extends State<SearchableCheckboxDialog> {
  late final TextEditingController _newValueController;
  late List<String> _options;
  late Set<String> _selected;
  String _filter = '';

  String _k(String value) => value.trim().toLowerCase();

  int _sortSelectedFirst(String a, String b) {
    final aSel = _selected.contains(a);
    final bSel = _selected.contains(b);
    if (aSel && !bSel) return -1;
    if (!aSel && bSel) return 1;
    return _k(a).compareTo(_k(b));
  }

  void _sortOptionsSelectedFirst() {
    _options.sort(_sortSelectedFirst);
  }

  @override
  void initState() {
    super.initState();
    _newValueController = TextEditingController();
    _options = {...widget.input_list, ...widget.preselected_list}.toList();
    _selected = widget.preselected_list.toSet();
    _sortOptionsSelectedFirst();
  }

  @override
  void dispose() {
    _newValueController.dispose();
    super.dispose();
  }

  void _addCustomValue() {
    final value = _newValueController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      final normalized = _k(value);
      if (!_options.any((option) => _k(option) == normalized)) {
        _options.add(value);
      }

      final existing = _options.firstWhere(
        (option) => _k(option) == normalized,
      );
      _selected.add(existing);
      _sortOptionsSelectedFirst();
      _newValueController.clear();
      _filter = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = _filter.trim().isEmpty
        ? [..._options]
        : _options
            .where(
              (option) => _k(option).contains(_k(_filter)),
            )
            .toList();
    filteredOptions.sort(_sortSelectedFirst);
    final hasExactMatch = _options.any(
      (option) => _k(option) == _k(_filter),
    );

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: _options.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _selected = _options.toSet();
                            _sortOptionsSelectedFirst();
                          });
                        },
                  icon: const Icon(Icons.done_all),
                  label: const Text('Seleziona tutto'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _selected.clear();
                            _sortOptionsSelectedFirst();
                          });
                        },
                  child: const Text('Pulisci'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newValueController,
                    decoration: InputDecoration(
                      labelText: widget.inputLabel,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _filter = value;
                      });
                    },
                    onSubmitted: (_) => _addCustomValue(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _filter.trim().isEmpty ? null : _addCustomValue,
                  child: Text(hasExactMatch ? 'Seleziona' : 'Aggiungi'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: filteredOptions.isEmpty
                  ? const Center(child: Text('Nessun valore trovato'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredOptions.length,
                      itemBuilder: (context, index) {
                        final option = filteredOptions[index];
                        final selected = _selected.contains(option);
                        return CheckboxListTile(
                          value: selected,
                          contentPadding: EdgeInsets.zero,
                          title: Text(option),
                          onChanged: (value) {
                            setState(() {
                              if (value ?? false) {
                                _selected.add(option);
                              } else {
                                _selected.remove(option);
                              }
                              _sortOptionsSelectedFirst();
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            final output_list = _selected.toList()..sort();
            Navigator.pop(context, output_list);
          },
          child: Text('Conferma (${_selected.length})'),
        ),
      ],
    );
  }
}
