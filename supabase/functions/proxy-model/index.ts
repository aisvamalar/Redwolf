// Edge Function to proxy GLB files with proper CORS headers for Google Scene Viewer
import { corsHeaders } from '../_shared/cors.ts'

const STORAGE_BASE_URL = 'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public'

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the model path from query parameter
    const url = new URL(req.url)
    const modelPath = url.searchParams.get('path')
    
    if (!modelPath) {
      return new Response(
        JSON.stringify({ error: 'Missing path parameter. Use ?path=products/products/glb/filename.glb' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

    // Construct the full storage URL
    const storageUrl = `${STORAGE_BASE_URL}/${modelPath}`
    
    console.log('Proxying model from:', storageUrl)

    // Fetch the model file from Supabase Storage
    const response = await fetch(storageUrl, {
      method: 'GET',
      headers: {
        'Accept': 'model/gltf-binary,application/octet-stream,*/*',
      },
    })

    if (!response.ok) {
      return new Response(
        JSON.stringify({ 
          error: 'Failed to fetch model',
          status: response.status,
          statusText: response.statusText 
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: response.status,
        }
      )
    }

    // Get the file content
    const blob = await response.blob()
    
    // Return the file with proper CORS headers and content type
    return new Response(blob, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'model/gltf-binary',
        'Content-Disposition': `inline; filename="${modelPath.split('/').pop()}"`,
        'Cache-Control': 'public, max-age=31536000, immutable',
      },
      status: 200,
    })
  } catch (error) {
    console.error('Error proxying model:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})









