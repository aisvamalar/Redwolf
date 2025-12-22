# Background Removal Setup Guide

## Overview
The app includes background removal functionality for product images fetched from Supabase. This feature uses the remove.bg API to automatically remove backgrounds from product images.

## Setup Instructions

### Option 1: Using remove.bg API (Recommended for Production)

1. **Get a free API key:**
   - Visit: https://www.remove.bg/api
   - Sign up for a free account
   - Get your API key from the dashboard

2. **Configure the API key:**
   - Open `lib/config/supabase_config.dart`
   - Replace `YOUR_REMOVE_BG_API_KEY` with your actual API key:
   ```dart
   static const String removeBgApiKey = 'your-actual-api-key-here';
   static const bool enableBackgroundRemoval = true;
   ```

3. **Free Tier Limits:**
   - Free tier: 50 API calls per month
   - Images are cached to minimize API calls
   - Processed images are stored in memory cache

### Option 2: Disable Background Removal

If you don't want to use background removal:
- Set `enableBackgroundRemoval = false` in `lib/config/supabase_config.dart`
- The app will display original images from Supabase

## How It Works

1. When a product image is loaded, the app checks if background removal is enabled
2. If enabled and API key is configured, the image is sent to remove.bg API
3. The processed image (with transparent background) is cached
4. Subsequent loads use the cached version to avoid API calls

## Notes

- Background removal is processed asynchronously
- Original images are shown while processing
- If API call fails, original image is displayed
- Cache persists during app session

