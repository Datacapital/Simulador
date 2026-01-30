#!/bin/bash
# Build script for Render Static Site
# Replaces placeholder tokens with environment variables

echo "Injecting environment variables..."

if [ -z "$SUPABASE_URL" ]; then
    echo "WARNING: SUPABASE_URL is not set"
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "WARNING: SUPABASE_ANON_KEY is not set"
fi

# Replace placeholders in index.html
sed -i "s|__SUPABASE_URL__|${SUPABASE_URL}|g" index.html
sed -i "s|__SUPABASE_ANON_KEY__|${SUPABASE_ANON_KEY}|g" index.html

echo "Build complete."
