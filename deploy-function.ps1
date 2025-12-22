# PowerShell script to deploy Supabase Edge Function
# Usage: .\deploy-function.ps1 -AccessToken "your-token-here"

param(
    [Parameter(Mandatory=$true)]
    [string]$AccessToken
)

# Set the access token as environment variable
$env:SUPABASE_ACCESS_TOKEN = $AccessToken

# Link the project
Write-Host "Linking to Supabase project..." -ForegroundColor Yellow
npx supabase link --project-ref zsipfgtlfnfvmnrohtdo

if ($LASTEXITCODE -eq 0) {
    Write-Host "Project linked successfully!" -ForegroundColor Green
    
    # Deploy the function
    Write-Host "Deploying proxy-model function..." -ForegroundColor Yellow
    npx supabase functions deploy proxy-model
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Function deployed successfully!" -ForegroundColor Green
        Write-Host "The proxy URL is now available at:" -ForegroundColor Cyan
        Write-Host "https://zsipfgtlfnfvmnrohtdo.supabase.co/functions/v1/proxy-model" -ForegroundColor Cyan
    } else {
        Write-Host "Function deployment failed!" -ForegroundColor Red
    }
} else {
    Write-Host "Project linking failed!" -ForegroundColor Red
}



