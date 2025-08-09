import 'package:flutter/material.dart';
import '../models/crop.dart';

class AddCropDialog extends StatefulWidget {
  const AddCropDialog({super.key});

  @override
  State<AddCropDialog> createState() => _AddCropDialogState();
}

class _AddCropDialogState extends State<AddCropDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _varietyController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _plantingDate;
  DateTime? _harvestDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Crop'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Crop Name *'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              TextFormField(
                controller: _varietyController,
                decoration: const InputDecoration(labelText: 'Variety'),
              ),
              ListTile(
                title: const Text('Planting Date'),
                subtitle: Text(
                  _plantingDate?.toString().split(' ')[0] ?? 'Not set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _plantingDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Harvest Date'),
                subtitle: Text(
                  _harvestDate?.toString().split(' ')[0] ?? 'Not set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _harvestDate = date);
                  }
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              final crop = Crop(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                variety: _varietyController.text.isEmpty
                    ? null
                    : _varietyController.text,
                plantingDate: _plantingDate,
                harvestDate: _harvestDate,
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
                version: 1,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              Navigator.of(context).pop(crop);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
