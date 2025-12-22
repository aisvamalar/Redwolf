-- Add a test product to the database
-- Run this in Supabase Dashboard > SQL Editor
-- Update the thumbnail and model_url with actual filenames from your storage bucket

-- First, check what files you have in your storage bucket
-- Based on your storage, you have files like:
-- - thumbnail_1766310241573...
-- - 32_EASEL STANDEE .glb
-- - image2_1766310242591_i...
-- - image3_1766310243560_i...

-- Example: Insert product with files from your storage bucket
INSERT INTO products (name, category, description, thumbnail, model_url, key_features, technical_specs, images)
VALUES (
  'Easel Standee',
  'Standees',
  'Elegant easel standee design perfect for retail displays and exhibitions.',
  'thumbnail_1766310241573...',  -- Replace with actual thumbnail filename from your storage
  '32_EASEL STANDEE .glb',        -- This file exists in your storage
  '["2 Years Warranty", "4K Display", "Portable Design", "Touch Enabled"]'::jsonb,
  '{
    "Model": "32\" Easel Standee",
    "Software Mode": "Online/Offline",
    "Display Resolution": "4K",
    "Brightness": "400 nits",
    "Aspect Ratio": "9:16",
    "Viewing Angle": "178°/178°",
    "Operating Hours": "10-12 Hours/Day",
    "Colour": "Black",
    "Storage": "2 GB RAM, 16 GB ROM",
    "Connectivity": "Wi-Fi / USB",
    "Stable Voltage": "50HZ; 100-240V AC",
    "Power Supply": "50W Max",
    "Working Temperature": "0-40°c",
    "Warranty": "One Year"
  }'::jsonb,
  '["thumbnail_1766310241573...", "image2_1766310242591_i...", "image3_1766310243560_i..."]'::jsonb
);

-- Verify the product was inserted
SELECT 
  id,
  name,
  category,
  thumbnail,
  model_url,
  created_at
FROM products
ORDER BY created_at DESC;

-- To see all product details:
-- SELECT * FROM products;



