# Troubleshooting: Why Old Products Are Showing

## Problem
Old/hardcoded products are appearing instead of products from the database.

## Solution Applied
✅ **Fallback products are now DISABLED by default**
- The app will only show products from the database
- If the database is empty, it will show an error message instead of fallback products

## How to Debug

### 1. Check Browser Console
Open your browser's developer console (F12) and look for these messages:

- ✅ `Successfully fetched X products from database` - Database is working!
- ⚠️ `No products found in database!` - Database table is empty
- ❌ `Supabase client not initialized!` - Supabase initialization failed
- ❌ `Error fetching products from Supabase` - Database connection/query failed

### 2. Verify Database Table Exists
1. Go to Supabase Dashboard → Table Editor
2. Check if `products` table exists
3. If not, create it using the SQL from `DATABASE_SCHEMA.md`

### 3. Check Database Permissions (RLS)
1. Go to Supabase Dashboard → Authentication → Policies
2. Make sure the `products` table has public read access:
   ```sql
   -- Allow public read access
   CREATE POLICY "Allow public read access" 
   ON products FOR SELECT 
   USING (true);
   ```

### 4. Verify Supabase Initialization
Check `lib/main.dart` - Supabase should be initialized:
```dart
await Supabase.initialize(
  url: SupabaseConfig.supabaseUrl,
  anonKey: SupabaseConfig.publishableKey,
);
```

### 5. Test Database Connection
Run this in your browser console after the app loads:
```javascript
// Check if Supabase is initialized
console.log('Supabase client:', window.supabase);
```

## Common Issues

### Issue 1: "No products found in database"
**Solution:** Add products via admin panel or directly in Supabase dashboard

### Issue 2: "Supabase client not initialized"
**Solution:** 
- Check `lib/main.dart` - ensure `main()` is `async`
- Verify Supabase credentials in `lib/config/supabase_config.dart`

### Issue 3: "Error fetching products from Supabase"
**Possible causes:**
- Table doesn't exist → Create it using `DATABASE_SCHEMA.md`
- RLS policies blocking access → Add public read policy
- Wrong table name → Ensure table is named `products` (lowercase)
- Network/CORS issues → Check browser console for CORS errors

### Issue 4: Products exist but not showing
**Check:**
- Products have `model_url` field (required for display)
- Products have required fields: `id`, `name`, `image_url`
- Check browser console for parsing errors

## Re-enable Fallback Products (if needed)

If you want to show hardcoded products when database is empty:

1. Open `lib/controllers/product_controller.dart`
2. Find line ~45 and uncomment:
   ```dart
   // Change from:
   // _allProducts = _getFallbackProducts();
   
   // To:
   _allProducts = _getFallbackProducts();
   ```

## Next Steps

1. ✅ Check browser console for error messages
2. ✅ Verify `products` table exists in Supabase
3. ✅ Add at least one product to the database
4. ✅ Refresh the app to see database products

## Database Schema

See `DATABASE_SCHEMA.md` for the complete table structure.



