import 'package:flutter/material.dart';
import '../services/user_service.dart';

class EditProfileDialog extends StatefulWidget {
  final UserProfile? profile;

  const EditProfileDialog({super.key, this.profile});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _farmSizeController;
  late TextEditingController _experienceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _phoneController = TextEditingController(text: widget.profile?.phone ?? '');
    _emailController = TextEditingController(text: widget.profile?.email ?? '');
    _locationController = TextEditingController(
      text: widget.profile?.location ?? '',
    );
    _farmSizeController = TextEditingController(
      text: widget.profile?.farmSize?.toString() ?? '',
    );
    _experienceController = TextEditingController(
      text: widget.profile?.experienceYears?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (value) =>
                    value?.isEmpty == true ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: _farmSizeController,
                decoration: const InputDecoration(
                  labelText: 'Farm Size (acres)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Experience (years)',
                ),
                keyboardType: TextInputType.number,
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
              final profile = UserProfile(
                id: widget.profile?.id,
                name: _nameController.text,
                phone: _phoneController.text.isEmpty
                    ? null
                    : _phoneController.text,
                email: _emailController.text.isEmpty
                    ? null
                    : _emailController.text,
                location: _locationController.text.isEmpty
                    ? null
                    : _locationController.text,
                farmSize: double.tryParse(_farmSizeController.text),
                experienceYears: int.tryParse(_experienceController.text),
              );
              Navigator.of(context).pop(profile);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
