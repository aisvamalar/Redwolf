# Quick Start Guide - Add Products to Database

## Current Status ✅
- ✅ Database connection is working
- ✅ `products` table exists
- ⚠️ Table is empty (0 products)

## Step 1: Check Your Storage Files

Go to your Supabase Storage: https://supabase.com/dashboard/project/zsipfgtlfnfvmnrohtdo/storage/files/buckets/products

Note down the exact filenames:
- **Thumbnail images**: e.g., `thumbnail_1766310241573...`
- **GLB files**: e.g., `32_EASEL STANDEE .glb`
- **Additional images**: e.g., `image2_1766310242591_i...`

## Step 2: Add Product via SQL

1. Go to **Supabase Dashboard** → **SQL Editor**
2. Run this SQL (update filenames with your actual files):

```sql
INSERT INTO products (name, category, description, thumbnail, model_url, key_features, technical_specs)
VALUES (
  'Easel Standee',
  'Standees',
  'Elegant easel standee design perfect for retail displays and exhibitions.',
  'thumbnail_1766310241573...',  -- Replace with your actual thumbnail filename
  '32_EASEL STANDEE .glb',        -- Replace with your actual GLB filename
  '["2 Years Warranty", "4K Display", "Portable Design", "Touch Enabled"]'::jsonb,
  '{"Model": "32\" Easel Standee", "Display Resolution": "4K", "Brightness": "400 nits"}'::jsonb
);
```

3. Click **Run** or press `Ctrl+Enter`

## Step 3: Verify Product Was Added

```sql
SELECT * FROM products;
```

You should see your product listed.

## Step 4: Refresh Your Webapp

Refresh your Flutter webapp - the product should now appear! 🎉

## Alternative: Add Multiple Products

```sql
-- Product 1
INSERT INTO products (name, category, description, thumbnail, model_url, key_features, technical_specs)
VALUES (
  'Easel Standee',
  'Standees',
  'Elegant easel standee design.',
  'thumbnail_1766310241573...',
  '32_EASEL STANDEE .glb',
  '["2 Years Warranty", "4K Display"]'::jsonb,
  '{"Model": "32\" Easel Standee", "Resolution": "4K"}'::jsonb
);

-- Product 2 (if you have more files)
INSERT INTO products (name, category, description, thumbnail, model_url, key_features, technical_specs)
VALUES (
  'Another Product',
  'Standees',
  'Product description here.',
  'image2_1766310242591_i...',  -- Use another image file
  'model_1766310244302_32...',  -- Use another GLB file
  '["Feature 1", "Feature 2"]'::jsonb,
  '{"Model": "Product Model", "Resolution": "4K"}'::jsonb
);
```

## Important Notes

1. **File Paths**: 
   - If file is in root: Just use filename (e.g., `32_EASEL STANDEE .glb`)
   - If file is in folder: Use path (e.g., `img/thumbnail.png` or `glb/model.glb`)

2. **File Names**: Use the EXACT filename from your storage bucket (case-sensitive)

3. **Required Fields**:
   - `name` ✅
   - `category` ✅
   - `description` ✅
   - `thumbnail` ✅ (must match a file in storage)
   - `model_url` ✅ (must match a GLB file in storage for AR to work)

4. **Optional Fields**:
   - `images` - Array of additional image filenames
   - `key_features` - Array of strings
   - `technical_specs` - Object with key-value pairs

## Troubleshooting

### Product not showing?
- Check browser console for errors
- Verify product has `thumbnail` and `model_url` fields
- Ensure files exist in storage bucket
- Check RLS policies allow public read

### Images not loading?
- Verify filenames match exactly (case-sensitive)
- Check files are in public bucket
- Ensure file paths are correct

### AR not working?
- Verify `model_url` points to a valid GLB file
- Check GLB file exists in storage
- Ensure file is accessible (public bucket)



