import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_button.dart';

/// Solid background (white in light, black in dark), labeled fields.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  String _photoPreview = '';
  bool _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _photoPreview = user?.photoUrl ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final ctrl = TextEditingController(text: _photoPreview);
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Profile photo',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                      labelText: 'Photo link', prefixIcon: Icon(Icons.link_outlined))),
              const SizedBox(height: 16),
              CommonButton(text: 'Use photo', onPressed: () => Navigator.pop(ctx, ctrl.text.trim())),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) setState(() => _photoPreview = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _formError = null;
    });
    final ok = await context.read<AuthProvider>().updateName(_name.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      setState(() => _formError = 'Could not save. Try again.');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final initial = _name.text.trim().isNotEmpty ? _name.text.trim()[0].toUpperCase() : '?';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: Text('Edit Profile',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage:
                            _photoPreview.isNotEmpty ? CachedNetworkImageProvider(_photoPreview) : null,
                        child: _photoPreview.isEmpty
                            ? Text(initial,
                                style: text.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 36))
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration:
                              BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                          child: Icon(Icons.camera_alt, size: 14, color: scheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                  child: Text('Tap to change photo',
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
              const SizedBox(height: 24),
              Text('Full Name', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(hintText: 'Ronit Agrawal'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              Text('Email', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextFormField(controller: _email, decoration: const InputDecoration(hintText: 'ronit@example.com')),
              if (_formError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                  child: Text(_formError!,
                      style: text.bodySmall?.copyWith(color: scheme.onErrorContainer)),
                ),
              ],
              const SizedBox(height: 24),
              CommonButton(text: 'Save Changes', isLoading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
