# iPad AR Quick Look Fix Instructions

## Problem
iPad AR Quick Look gets stuck at "Opening AR view..." screen. This is caused by one or more of these issues:

1. **Filename issues** (spaces, trailing spaces, uppercase)
2. **MIME type not set correctly on Supabase storage**
3. **Invalid or corrupted USDZ file**

## Fixes Applied

### ✅ 1. URL Normalization (Code Fix)
- Automatically trims trailing spaces from filenames
- Properly encodes spaces in URLs
- Validates and warns about problematic filenames
- Preserves case sensitivity while encoding

### ✅ 2. Vercel Configuration
- Created `vercel.json` with proper MIME type headers for USDZ files
- Note: This only applies if files are served through Vercel. If files are on Supabase storage, you need to fix MIME types there.

## Required Actions (You Need to Do)

### 🔴 CRITICAL: Fix MIME Type on Supabase Storage

The USDZ files on Supabase storage need to have the correct MIME type set. Here's how to fix it:

#### Option 1: Using Supabase Dashboard
1. Go to Supabase Dashboard → Storage
2. Navigate to your bucket (e.g., `products`)
3. Find the `usdz/` folder
4. For each USDZ file:
   - Click on the file
   - Update the metadata:
     - `Content-Type`: `model/vnd.usdz+zip`
     - `Content-Disposition`: `inline`

#### Option 2: Using Supabase CLI or API
```bash
# Update MIME type for a specific file
supabase storage update \
  --bucket products \
  --path usdz/32_easel_standee.usdz \
  --metadata '{"Content-Type": "model/vnd.usdz+zip", "Content-Disposition": "inline"}'
```

#### Option 3: Re-upload with Correct Headers
When uploading USDZ files to Supabase storage, ensure these headers are set:
- `Content-Type: model/vnd.usdz+zip`
- `Content-Disposition: inline`

### 🔴 CRITICAL: Fix Filename Issues

If your filenames have problems like:
- `32_EASEL STANDEE .usdz` (spaces, uppercase, trailing space)

**Rename them to:**
- `32_easel_standee.usdz` (lowercase, underscores, no trailing space)

**Then update your database:**
- Update the `usdzFileUrl` field in your products table to point to the new filename

### ✅ Validate USDZ File

Test if the USDZ file is valid:
1. Download the USDZ file to your iPad
2. Open Files app
3. Tap the USDZ file
4. **If it opens in AR**: File is valid ✅
5. **If it's stuck/black**: File is broken ❌ (re-export from Blender/3D software)

## Testing

After applying fixes:
1. Clear browser cache on iPad
2. Try "View In My Space" button
3. Check browser console for debug logs
4. AR Quick Look should open successfully

## Debug Logs

The code now outputs detailed debug information:
- ✅ URL validation
- ✅ Filename cleaning (removes trailing spaces)
- ✅ URL encoding
- ✅ Case sensitivity verification
- ⚠️ Warnings about problematic filenames
- ⚠️ MIME type reminders

Check the browser console on iPad Safari (connect iPad to Mac, use Safari Web Inspector) to see these logs.

## Common Issues

| Issue | Symptom | Fix |
|-------|---------|-----|
| Trailing space in filename | AR freezes | Code now auto-trims, but rename file in database |
| Spaces in filename | AR freezes | Code now encodes, but rename file for best results |
| Wrong MIME type | AR freezes | Set `Content-Type: model/vnd.usdz+zip` on Supabase |
| Invalid USDZ file | AR freezes | Re-export from 3D software, validate in Files app |
| Uppercase filename | May cause issues | Rename to lowercase (code preserves case but warns) |

## Best Practices

1. **Filenames**: Use lowercase, underscores, no spaces
   - ✅ `32_easel_standee.usdz`
   - ❌ `32_EASEL STANDEE .usdz`

2. **MIME Type**: Always set on upload
   - `Content-Type: model/vnd.usdz+zip`
   - `Content-Disposition: inline`

3. **File Validation**: Test in Files app before deploying

4. **Export Settings**: When exporting USDZ:
   - Apply transforms in Blender
   - Set origin to bottom center
   - Scale to real-world meters
   - Embed all textures (don't use external paths)

