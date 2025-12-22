# Supabase Edge Functions

This directory contains Edge Functions for the Redwolf project.

## Functions

### proxy-model

Proxies GLB model files from Supabase Storage with proper CORS headers for Google Scene Viewer.

**Usage:**
```
https://zsipfgtlfnfvmnrohtdo.supabase.co/functions/v1/proxy-model?path=products/products/glb/filename.glb
```

**Parameters:**
- `path` (required): The path to the model file in storage (relative to `/object/public/`)

**Example:**
```
https://zsipfgtlfnfvmnrohtdo.supabase.co/functions/v1/proxy-model?path=products/products/glb/32_EASEL%20STANDEE%20.glb
```

## Deployment

To deploy the Edge Functions, you need the Supabase CLI:

1. **Install Supabase CLI** (if not already installed):
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link your project**:
   ```bash
   supabase link --project-ref zsipfgtlfnfvmnrohtdo
   ```

4. **Deploy the functions**:
   ```bash
   supabase functions deploy proxy-model
   ```

## Testing

After deployment, test the function:
```bash
curl "https://zsipfgtlfnfvmnrohtdo.supabase.co/functions/v1/proxy-model?path=products/products/glb/32_EASEL%20STANDEE%20.glb"
```

The function should return the GLB file with proper CORS headers.
