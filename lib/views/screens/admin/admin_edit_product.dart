import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../config/supabase_config.dart';
import '../../../models/product.dart';
import '../../../services/supabase_service.dart';
import 'admin_product_form.dart';

class AdminEditProduct extends StatefulWidget {
  final Product product;

  const AdminEditProduct({super.key, required this.product});

  @override
  State<AdminEditProduct> createState() => _AdminEditProductState();
}

class _AdminEditProductState extends State<AdminEditProduct> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _keyFeaturesController;
  late final TextEditingController _technicalSpecsController;

  // File paths
  String? _thumbnailPath;
  String? _modelPath;
  List<String> _additionalImages = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _categoryController = TextEditingController(text: widget.product.category);
    _descriptionController = TextEditingController(text: widget.product.description);
    
    // Set key features
    if (widget.product.keyFeatures != null && widget.product.keyFeatures!.isNotEmpty) {
      _keyFeaturesController = TextEditingController(
        text: widget.product.keyFeatures!.join(', '),
      );
    } else {
      _keyFeaturesController = TextEditingController();
    }

    // Set technical specs (convert from specifications list to JSON)
    if (widget.product.specifications != null && widget.product.specifications!.isNotEmpty) {
      final specsMap = <String, String>{};
      for (var spec in widget.product.specifications!) {
        if (spec.containsKey('label') && spec.containsKey('value')) {
          specsMap[spec['label']!] = spec['value']!;
        }
      }
      _technicalSpecsController = TextEditingController(
        text: const JsonEncoder.withIndent('  ').convert(specsMap),
      );
    } else {
      _technicalSpecsController = TextEditingController();
    }

    // Set file paths
    _thumbnailPath = widget.product.imageUrl;
    _modelPath = widget.product.glbFileUrl ?? widget.product.modelUrl;
    _additionalImages = widget.product.images ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _keyFeaturesController.dispose();
    _technicalSpecsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse key features
      List<String> keyFeatures = [];
      if (_keyFeaturesController.text.isNotEmpty) {
        keyFeatures = _keyFeaturesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      // Parse technical specs
      Map<String, String> technicalSpecs = {};
      if (_technicalSpecsController.text.isNotEmpty) {
        try {
          final decoded = jsonDecode(_technicalSpecsController.text) as Map;
          technicalSpecs = decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid technical specs JSON: $e')),
            );
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      // Get thumbnail URL
      String thumbnailUrl = _thumbnailPath ?? widget.product.imageUrl;
      if (!thumbnailUrl.startsWith('http')) {
        thumbnailUrl = SupabaseService.getStorageUrl('products/img', thumbnailUrl);
      }

      // Get model URL
      String? modelUrl = _modelPath ?? widget.product.glbFileUrl ?? widget.product.modelUrl;
      if (modelUrl != null && !modelUrl.startsWith('http')) {
        modelUrl = SupabaseService.getStorageUrl('products/glb', modelUrl);
      }

      // Prepare update data
      final updateData = {
        'name': _nameController.text,
        'category': _categoryController.text,
        'description': _descriptionController.text,
        'thumbnail': thumbnailUrl,
        if (modelUrl != null) 'model_url': modelUrl,
        'key_features': keyFeatures,
        'technical_specs': technicalSpecs,
        if (_additionalImages.isNotEmpty) 'images': _additionalImages,
      };

      // Update in database
      final supabase = SupabaseConfig.supabaseClient;
      if (supabase == null) {
        throw Exception('Supabase client not initialized');
      }

      if (widget.product.id == null) {
        throw Exception('Product ID is null');
      }
      
      await supabase
          .from('products')
          .update(updateData)
          .eq('id', widget.product.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminProductForm(
      formKey: _formKey,
      isLoading: _isLoading,
      nameController: _nameController,
      categoryController: _categoryController,
      descriptionController: _descriptionController,
      keyFeaturesController: _keyFeaturesController,
      technicalSpecsController: _technicalSpecsController,
      thumbnailPath: _thumbnailPath,
      modelPath: _modelPath,
      additionalImages: _additionalImages,
      onThumbnailSelected: (path) => setState(() => _thumbnailPath = path),
      onModelSelected: (path) => setState(() => _modelPath = path),
      onAdditionalImageSelected: (path) => setState(() => _additionalImages.add(path)),
      onSubmit: _submitForm,
      isEditMode: true,
    );
  }
}



