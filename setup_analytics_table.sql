-- Create analytics table for tracking product views and AR views
CREATE TABLE IF NOT EXISTS analytics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_type TEXT NOT NULL CHECK (event_type IN ('product_view', 'ar_view')),
  product_id TEXT,
  user_id TEXT,
  session_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_analytics_event_type ON analytics(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_created_at ON analytics(created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_product_id ON analytics(product_id);

-- Enable Row Level Security (RLS)
ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public read access (for admin dashboard)
CREATE POLICY "Allow public read access" ON analytics
  FOR SELECT
  USING (true);

-- Policy: Allow public insert (for tracking events)
CREATE POLICY "Allow public insert" ON analytics
  FOR INSERT
  WITH CHECK (true);

-- Grant necessary permissions
GRANT SELECT, INSERT ON analytics TO anon;
GRANT SELECT, INSERT ON analytics TO authenticated;

