# Admin Panel Integration Guide

## Overview
This document explains how to integrate the admin panel codebase from `Redwolf_AdminPanel` into the main webapp.

## Files to Copy

### Models
- ✅ `lib/models/admin_product.dart` - Product model for admin panel
- ✅ `lib/models/admin_category.dart` - Category model

### Services  
- ✅ `lib/services/admin_supabase_service.dart` - Supabase service for admin (file uploads)
- Need to create: `lib/services/admin_product_service.dart`
- Need to create: `lib/services/admin_category_service.dart`

### Pages
- Need to create: `lib/pages/admin/dashboard_page.dart`
- Need to create: `lib/pages/admin/products_page.dart`
- Need to create: `lib/pages/admin/add_product_page.dart`
- Need to create: `lib/pages/admin/login_page.dart`

### Widgets
- Need to create: `lib/widgets/admin/sidebar.dart`
- Need to create: `lib/widgets/admin/footer.dart`
- Need to create: `lib/widgets/admin/manage_category_dialog.dart`

## Key Features

1. **File Upload from Device**
   - Uses `file_picker` package
   - Supports image uploads (3 images: thumbnail + 2 additional)
   - Supports GLB and USDZ file uploads for 3D models
   - Files uploaded directly to Supabase Storage

2. **Product Management**
   - Add/Edit/Delete products
   - Product status (Draft/Published)
   - Categories management
   - Specifications and key features

3. **UI Structure**
   - Sidebar navigation
   - Dashboard with metrics
   - Products list with search and filters
   - Add/Edit product form with file uploads

## Integration Steps

1. ✅ Add dependencies to `pubspec.yaml`
2. ✅ Create admin models
3. ✅ Create admin Supabase service
4. ⏳ Create admin services (ProductService, CategoryService)
5. ⏳ Create admin pages
6. ⏳ Create admin widgets
7. ⏳ Update main.dart routing
8. ⏳ Test file uploads

## File Upload Implementation

The admin panel uses `file_picker` to allow users to:
- Select images from device (3 images required)
- Select GLB or USDZ files from device
- Files are uploaded to Supabase Storage with proper paths:
  - Images: `products/img/{filename}`
  - Models: `products/glb/{filename}`

## Next Steps

Continue copying the remaining files from the admin panel codebase, adapting imports to work with the webapp structure.



