# Deploy Edge Function - Instructions

## Quick Deploy (Recommended)

Run these commands in your terminal:

```bash
# 1. Login to Supabase (opens browser for authentication)
npx supabase login

# 2. Link your project
npx supabase link --project-ref zsipfgtlfnfvmnrohtdo

# 3. Deploy the function
npx supabase functions deploy proxy-model
```

## Alternative: Using Access Token

1. **Get your access token:**
   - Go to: https://supabase.com/dashboard/account/tokens
   - Create a new access token (or use existing one)

2. **Set the token and deploy:**
   ```powershell
   # PowerShell
   $env:SUPABASE_ACCESS_TOKEN = "your-token-here"
   npx supabase link --project-ref zsipfgtlfnfvmnrohtdo
   npx supabase functions deploy proxy-model
   ```

   Or use the provided script:
   ```powershell
   .\deploy-function.ps1 -AccessToken "your-token-here"
   ```

## Verify Deployment

After deployment, test the function:
```bash
curl "https://zsipfgtlfnfvmnrohtdo.supabase.co/functions/v1/proxy-model?path=products/products/glb/32_EASEL%20STANDEE%20(1).glb"
```

You should receive the GLB file with proper CORS headers.

## Troubleshooting

- If you get "Access token not provided", make sure you've run `supabase login` first
- If deployment fails, check that you have the correct project permissions
- The function will be available at: `https://zsipfgtlfnfvmnrohtdo.supabase.co/functions/v1/proxy-model`

