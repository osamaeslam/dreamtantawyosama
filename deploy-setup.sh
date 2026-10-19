#!/bin/bash
# Deployment setup script for Tantawy Group Flutter app
# Run this after creating GitHub repository and setting up Vercel

echo "=== Tantawy Group Deployment Setup ==="
echo ""

# 1. Check if GitHub repository exists
echo "1. Creating GitHub repository..."
echo "Please create the repository at: https://github.com/new"
echo "Repository name: dreamtantawyosama-main"
echo "Do NOT initialize with README, .gitignore, or license"
echo ""
echo "After creating, press Enter to continue..."
read

# 2. Add remote and push
echo "2. Adding remote and pushing to GitHub..."
git remote add origin https://github.com/osama/dreamtantawyosama-main.git
git branch -M main
git push -u origin main
echo ""

# 3. Instructions for Vercel
echo "3. Setting up Vercel deployment:"
echo "   a. Go to https://vercel.com/new"
echo "   b. Import your GitHub repository: dreamtantawyosama-main"
echo "   c. In Project Settings > Environment Variables, add:"
echo "      - VERCEL_TOKEN"
echo "      - VERCEL_ORG_ID"
echo "      - VERCEL_PROJECT_ID"
echo "   d. Or set up GitHub Secrets (Settings > Secrets > Actions):"
echo "      - VERCEL_TOKEN"
echo "      - VERCEL_ORG_ID"
echo "      - VERCEL_PROJECT_ID"
echo "      - VERCEL_SCOPE"
echo ""

# 4. Download APK if workflow runs
echo "4. APK will be available as a build artifact in GitHub Actions"
echo "   after the first push completes."
echo ""

echo "=== Setup Complete! ==="