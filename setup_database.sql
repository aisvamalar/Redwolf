-- Create products table in Supabase
-- Run this in Supabase Dashboard > SQL Editor

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Standees',
  description TEXT NOT NULL,
  thumbnail TEXT NOT NULL, -- Image filename or path in products bucket
  model_url TEXT, -- GLB filename or path in products bucket
  images JSONB, -- Array of image filenames/paths
  key_features JSONB, -- Array of feature strings
  technical_specs JSONB, -- Object with specifications
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

-- Enable Row Level Security (RLS)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public read access
CREATE POLICY "Allow public read access" 
ON products FOR SELECT 
USING (true);

-- Example: Insert a test product
-- Update the thumbnail and model_url with actual filenames from your storage bucket
INSERT INTO products (name, category, description, thumbnail, model_url, key_features, technical_specs)
VALUES (
  'Easel Standee',
  'Standees',
  'Elegant easel standee design perfect for retail displays and exhibitions.',
  'thumbnail_1766310241573...', -- Replace with actual thumbnail filename from storage
  '32_EASEL STANDEE .glb', -- Replace with actual GLB filename from storage
  '["2 Years Warranty", "4K Display", "Portable Design", "Touch Enabled"]'::jsonb,
  '{"Model": "32\" Easel Standee", "Display Resolution": "4K", "Brightness": "400 nits"}'::jsonb
);

-- Check if products were inserted
SELECT * FROM products;



