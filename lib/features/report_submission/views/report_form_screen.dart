import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../models/disease_list.dart';
import '../viewmodel/report_viewmodel.dart';
import '../../outbreak_map/views/clinic_list_screen.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthViewModel>().currentUser?.id ?? 'unknown';
    final vm = context.read<ReportViewModel>();
    final lat = vm.latitude;
    final lng = vm.longitude;

    final ok = await vm.submitReport(
      userId: userId,
      symptoms: _symptomsController.text.trim(),
    );

    if (!mounted) return;
    final queued = vm.lastSubmitQueued;
    if (ok && lat != null && lng != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(queued
            ? 'No internet. Your report is saved on this phone and will be sent automatically.'
            : 'Report submitted. Waiting for health officer review.'),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClinicListScreen(latitude: lat, longitude: lng),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Report Symptoms')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'This app does not give medical advice or diagnoses. '
                          'Reports are reviewed by health officers. '
                          'In an emergency, call 999.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: vm.selectedDisease,
                    decoration: const InputDecoration(
                      labelText: 'Suspected disease',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: inScopeDiseases
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: vm.setDisease,
                    validator: (v) => v == null ? 'Choose a disease' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _symptomsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Describe your symptoms',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Please write at least 10 characters'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Photo
                  if (vm.photoBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(vm.photoBytes!, height: 180, fit: BoxFit.cover),
                    ),
                    TextButton.icon(
                      onPressed: vm.removePhoto,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove photo'),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => vm.pickPhoto(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => vm.pickPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Location
                  OutlinedButton.icon(
                    onPressed: vm.isLocating ? null : vm.fetchLocation,
                    icon: vm.isLocating
                        ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: Text(
                      vm.latitude == null
                          ? 'Get my location'
                          : (vm.locationName ??
                          '${vm.latitude!.toStringAsFixed(4)}, ${vm.longitude!.toStringAsFixed(4)}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Anonymous switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Report anonymously'),
                    subtitle: const Text('Your name is hidden on the public feed'),
                    value: vm.isAnonymous,
                    onChanged: vm.setAnonymous,
                  ),

                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(vm.errorMessage!, style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Submit Report',
                    isLoading: vm.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}