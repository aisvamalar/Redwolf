import 'package:flutter/material.dart';

class AdminProductForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final TextEditingController nameController;
  final TextEditingController categoryController;
  final TextEditingController descriptionController;
  final TextEditingController keyFeaturesController;
  final TextEditingController technicalSpecsController;
  final String? thumbnailPath;
  final String? modelPath;
  final List<String> additionalImages;
  final Function(String) onThumbnailSelected;
  final Function(String) onModelSelected;
  final Function(String) onAdditionalImageSelected;
  final VoidCallback onSubmit;
  final bool isEditMode;

  const AdminProductForm({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.nameController,
    required this.categoryController,
    required this.descriptionController,
    required this.keyFeaturesController,
    required this.technicalSpecsController,
    required this.thumbnailPath,
    required this.modelPath,
    required this.additionalImages,
    required this.onThumbnailSelected,
    required this.onModelSelected,
    required this.onAdditionalImageSelected,
    required this.onSubmit,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditMode ? 'Edit Product' : 'Add New Product',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              
              // Product Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Standees',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Thumbnail Image
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thumbnail Image *',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (thumbnailPath != null)
                        Text('Selected: $thumbnailPath'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // For web, show dialog to enter file path/URL
                          final controller = TextEditingController();
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Thumbnail Image'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'File path or URL',
                                  hintText: 'e.g., thumbnail.png or full URL',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(controller.text),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          if (result != null && result.isNotEmpty) {
                            onThumbnailSelected(result);
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('Select Thumbnail'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // GLB Model File
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3D Model (GLB)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (modelPath != null)
                        Text('Selected: $modelPath'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final controller = TextEditingController();
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('GLB Model File'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'File path or URL',
                                  hintText: 'e.g., model.glb or full URL',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(controller.text),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          if (result != null && result.isNotEmpty) {
                            onModelSelected(result);
                          }
                        },
                        icon: const Icon(Icons.view_in_ar),
                        label: const Text('Select GLB Model'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Key Features
              TextFormField(
                controller: keyFeaturesController,
                decoration: const InputDecoration(
                  labelText: 'Key Features',
                  border: OutlineInputBorder(),
                  hintText: 'Comma-separated: Feature 1, Feature 2, ...',
                  helperText: 'Enter features separated by commas',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Technical Specs
              TextFormField(
                controller: technicalSpecsController,
                decoration: const InputDecoration(
                  labelText: 'Technical Specifications (JSON)',
                  border: OutlineInputBorder(),
                  hintText: '{"Model": "32\\" Standee", "Resolution": "4K"}',
                  helperText: 'Enter as JSON object',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEditMode ? 'Update Product' : 'Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



