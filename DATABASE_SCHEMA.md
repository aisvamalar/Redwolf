# Database Schema for Products

This document describes the expected database schema for the `products` table in Supabase.

## Table: `products`

The products table should have the following columns to work with the application:

### Required Columns

| Column Name | Type | Description |
|------------|------|-------------|
| `id` | text/uuid | Unique identifier for the product (Primary Key) |
| `name` | text | Product name |
| `category` | text | Product category (e.g., "Standees") |
| `description` | text | Product description |
| `thumbnail` | text | **Thumbnail image** - Can be full URL or path in `products/products/img/` bucket |
| `model_url` | text (nullable) | **GLB file** - Can be full URL or path in `products/products/glb/` bucket for AR viewing |

### Optional Columns

| Column Name | Type | Description |
|------------|------|-------------|
| `image_url` | text | Alternative field name for thumbnail (for backward compatibility) |
| `images` | jsonb/array | Array of additional product image URLs or paths |
| `key_features` | jsonb/array | Array of key feature strings (e.g., ["2 Years Warranty", "4K Display"]) |
| `technical_specs` | jsonb/object | Object containing technical specifications (key-value pairs) |
| `specifications` | jsonb/object | Alternative field name for technical_specs |
| `created_at` | timestamp | Timestamp when product was created (used for sorting) |

## SQL Schema Example

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Standees',
  description TEXT NOT NULL,
  thumbnail TEXT NOT NULL, -- Thumbnail image (path in products/products/img/ or full URL)
  model_url TEXT, -- GLB file path (in products/products/glb/ or full URL)
  images JSONB, -- Array of additional image paths/URLs
  key_features JSONB, -- Array of feature strings
  technical_specs JSONB, -- Object with specifications
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create an index for faster queries
CREATE INDEX idx_products_created_at ON products(created_at DESC);
CREATE INDEX idx_products_category ON products(category);
```

## Field Name Variations

The application supports both snake_case and camelCase field names:
- `image_url` or `imageUrl`
- `model_url` or `modelUrl`
- `key_features` or `keyFeatures`
- `technical_specs` or `technicalSpecs`

## Example Data

### Option 1: Using Full URLs (Recommended for Admin Panel)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Easel Standee",
  "category": "Standees",
  "description": "Elegant easel standee design perfect for retail displays and exhibitions.",
  "thumbnail": "https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/img/product1.png",
  "model_url": "https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_EASEL%20STANDEE%20.glb",
  "images": [
    "https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/img/product1.png"
  ],
  "key_features": [
    "2 Years Warranty",
    "4K Display",
    "Portable Design",
    "Touch Enabled"
  ],
  "technical_specs": {
    "Model": "32\" Easel Standee",
    "Display Resolution": "4K",
    "Brightness": "400 nits"
  },
  "created_at": "2024-01-15T10:30:00Z"
}
```

### Option 2: Using Storage Paths (App will construct full URLs)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Easel Standee",
  "category": "Standees",
  "description": "Elegant easel standee design perfect for retail displays and exhibitions.",
  "thumbnail": "product1.png",
  "model_url": "32_EASEL STANDEE .glb",
  "images": ["product1.png", "product1-side.png"],
  "key_features": [
    "2 Years Warranty",
    "4K Display",
    "Portable Design",
    "Touch Enabled"
  ],
  "technical_specs": {
    "Model": "32\" Easel Standee",
    "Display Resolution": "4K",
    "Brightness": "400 nits"
  },
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Note:** The app automatically handles both full URLs and storage paths. If you provide just the filename (e.g., "product1.png"), it will construct the full URL using the storage bucket path.

## Admin Panel Integration

When products are uploaded via the admin panel:

1. **Upload Thumbnail Image:**
   - Upload to: `products/products/img/` bucket in Supabase Storage
   - Store the filename or full URL in the `thumbnail` field

2. **Upload GLB Model File:**
   - Upload to: `products/products/glb/` bucket in Supabase Storage
   - Store the filename or full URL in the `model_url` field

3. **Create Product Record:**
   - Insert into `products` table with:
     - `name`: Product name
     - `category`: Product category
     - `description`: Product description
     - `thumbnail`: Thumbnail image path/URL
     - `model_url`: GLB file path/URL
     - `key_features`: Array of feature strings (JSONB)
     - `technical_specs`: Object with specifications (JSONB)
     - `images`: Array of additional image paths/URLs (JSONB, optional)

4. **Storage Bucket Structure:**
   ```
   products/
   ├── products/
   │   ├── img/          (Thumbnail images)
   │   │   ├── product1.png
   │   │   ├── product2.jpg
   │   │   └── ...
   │   └── glb/          (3D model files)
   │       ├── model1.glb
   │       ├── model2.glb
   │       └── ...
   ```

5. **URL Format:**
   - You can use either full URLs: `https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/img/product1.png`
   - Or just filenames: `product1.png` (app will construct the full URL automatically)

## Notes

- Products without `model_url` will not appear in the home screen (only products with AR models are displayed)
- Products are ordered by `created_at` descending (newest first)
- If the database query fails, the app falls back to hardcoded products

