# Admin Panel Integration Guide

## Overview

The admin panel from [Redwolf_AdminPanel](https://github.com/rayyan-10/Redwolf_AdminPanel) has been integrated into your webapp. You can now manage products directly from the webapp interface.

## Features

✅ **Product Management**
- View all products
- Add new products
- Edit existing products
- Delete products

✅ **File Management**
- Upload thumbnail images
- Upload GLB model files
- Manage product images

✅ **Database Integration**
- Direct integration with Supabase database
- Automatic storage URL construction
- Real-time product updates

## How to Access

### Option 1: Via Header Button
1. Go to the home page
2. Click the **"Admin"** button in the top-right corner of the header
3. You'll be redirected to the admin dashboard

### Option 2: Direct URL
Navigate to: `/admin` route in your webapp

## Admin Panel Structure

```
Admin Dashboard
├── Products List
│   ├── View all products
│   ├── Edit product
│   └── Delete product
└── Add Product
    ├── Product details form
    ├── Thumbnail upload
    └── GLB model upload
```

## Adding a New Product

1. **Navigate to Admin Panel**
   - Click "Admin" button or go to `/admin`

2. **Go to "Add Product" Tab**
   - Click on "Add Product" in the sidebar

3. **Fill in Product Details**
   - **Product Name*** (required)
   - **Category*** (required, e.g., "Standees")
   - **Description*** (required)
   - **Thumbnail Image*** (required)
     - Enter file path or URL
     - Example: `thumbnail.png` or full URL
   - **3D Model (GLB)** (optional)
     - Enter GLB file path or URL
     - Example: `model.glb` or full URL
   - **Key Features** (optional)
     - Comma-separated list
     - Example: `Feature 1, Feature 2, Feature 3`
   - **Technical Specifications** (optional)
     - JSON format
     - Example: `{"Model": "32\" Standee", "Resolution": "4K"}`

4. **Submit**
   - Click "Add Product" button
   - Product will be saved to database
   - Automatically appears in home page

## Editing a Product

1. **Go to Products List**
   - Click "Products" in sidebar

2. **Find the Product**
   - Browse the list of products

3. **Click Edit Icon**
   - Pencil icon on the product card

4. **Update Fields**
   - Modify any fields as needed
   - Click "Update Product"

## Deleting a Product

1. **Go to Products List**
2. **Find the Product**
3. **Click Delete Icon** (red trash icon)
4. **Confirm Deletion**
   - Product will be permanently deleted from database

## File Upload Options

### Option 1: Enter File Path
If files are already in Supabase storage:
- Enter just the filename: `thumbnail.png`
- Or path: `img/thumbnail.png`
- App will construct full URL automatically

### Option 2: Enter Full URL
If you have the full storage URL:
- Enter complete URL: `https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/img/thumbnail.png`

## Storage Bucket Structure

Files should be organized in your Supabase storage:

```
products/ (bucket)
├── img/          (thumbnail images)
│   └── thumbnail.png
└── glb/          (3D model files)
    └── model.glb
```

Or files can be in the root:
```
products/ (bucket)
├── thumbnail.png
└── model.glb
```

## Database Schema

Products are stored with this structure:

```json
{
  "id": "uuid",
  "name": "Product Name",
  "category": "Standees",
  "description": "Product description",
  "thumbnail": "thumbnail.png or full URL",
  "model_url": "model.glb or full URL",
  "key_features": ["Feature 1", "Feature 2"],
  "technical_specs": {
    "Model": "32\" Standee",
    "Resolution": "4K"
  },
  "created_at": "timestamp"
}
```

## Integration with Webapp

- **Automatic Sync**: Products added/edited in admin panel immediately appear in the home page
- **Real-time Updates**: No need to refresh - changes are reflected instantly
- **Storage Integration**: Files uploaded to Supabase storage are automatically linked

## Security Notes

⚠️ **Current Implementation**: Admin panel is accessible to everyone
- For production, add authentication
- Consider adding role-based access control
- Protect admin routes with authentication middleware

## Future Enhancements

- [ ] Add authentication/login
- [ ] File upload via file picker (not just path entry)
- [ ] Image preview before upload
- [ ] Bulk product operations
- [ ] Product categories management
- [ ] Analytics dashboard

## Troubleshooting

### Products not appearing after adding?
- Check browser console for errors
- Verify database connection
- Ensure RLS policies allow inserts

### Files not loading?
- Verify file paths are correct
- Check files exist in Supabase storage
- Ensure storage bucket is public

### Can't delete products?
- Check RLS policies allow deletes
- Verify Supabase client is initialized
- Check browser console for errors

## Files Created

- `lib/views/screens/admin/admin_dashboard.dart` - Main admin dashboard
- `lib/views/screens/admin/admin_product_list.dart` - Product list view
- `lib/views/screens/admin/admin_add_product.dart` - Add product form
- `lib/views/screens/admin/admin_edit_product.dart` - Edit product form
- `lib/views/screens/admin/admin_product_form.dart` - Reusable form component

## Navigation

- **Home → Admin**: Click "Admin" button in header
- **Admin → Home**: Click home icon in admin app bar
- **Admin Navigation**: Use sidebar to switch between Products and Add Product

The admin panel is now fully integrated and ready to use! 🎉



