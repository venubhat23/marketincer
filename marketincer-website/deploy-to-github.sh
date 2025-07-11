#!/bin/bash

# Script to deploy Marketincer website to GitHub
# Usage: ./deploy-to-github.sh [your-github-username] [repository-name]

if [ $# -eq 0 ]; then
    echo "Usage: $0 <github-username> <repository-name>"
    echo "Example: $0 yourusername marketincer-website"
    echo ""
    echo "Before running this script:"
    echo "1. Create a new repository on GitHub"
    echo "2. Make sure you have git configured with your GitHub credentials"
    echo "3. Run this script with your GitHub username and repository name"
    exit 1
fi

USERNAME=$1
REPO_NAME=$2

echo "Setting up GitHub remote for $USERNAME/$REPO_NAME..."

# Add GitHub remote
git remote add origin https://github.com/$USERNAME/$REPO_NAME.git

# Rename master branch to main (GitHub's default)
git branch -M main

# Push to GitHub
echo "Pushing to GitHub..."
git push -u origin main

echo ""
echo "✅ Website successfully deployed to GitHub!"
echo "Repository URL: https://github.com/$USERNAME/$REPO_NAME"
echo ""
echo "To enable GitHub Pages:"
echo "1. Go to your repository on GitHub"
echo "2. Click on 'Settings' tab"
echo "3. Scroll down to 'Pages' section"
echo "4. Select 'Deploy from a branch' and choose 'main' branch"
echo "5. Your website will be available at: https://$USERNAME.github.io/$REPO_NAME"
echo ""
