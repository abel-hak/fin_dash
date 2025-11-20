# Pre-Push Checklist

Complete this checklist before pushing to your repository.

## Security (CRITICAL)

- [x] Removed all hardcoded API keys from lib/core/env_config.dart
- [x] Removed all hardcoded credentials from code
- [x] Verified .gitignore includes .env and *.env
- [x] Created .env.example with placeholder values
- [x] Added SECURITY.md file
- [ ] Double-check: Search entire codebase for "AIzaSy" - should find ZERO results in committed code
- [ ] Double-check: Search for "supabase.co" - should only be in .env.example

## Documentation

- [x] README.md has clear setup instructions
- [x] README.md explains how to get credentials
- [x] SECURITY.md explains security practices
- [x] CONTRIBUTING.md provides contribution guidelines
- [ ] Update README.md with your actual repository URL (line 53)
- [ ] Add LICENSE file if needed

## Code Quality

- [ ] Run flutter analyze - fix any errors
- [ ] Run flutter format . - format all files
- [ ] Remove any TODO comments that expose sensitive info
- [ ] Remove debug/test files not needed in production
- [ ] Check for print statements with sensitive data

## Files to Review

Must Include:
- .gitignore (with .env excluded)
- .env.example (with placeholders)
- README.md
- SECURITY.md
- CONTRIBUTING.md
- pubspec.yaml
- assets/templates.json

Must NOT Include:
- .env (actual credentials)
- *.iml files
- .idea/ folder
- build/ folder
- .dart_tool/ folder
- Any files with real API keys

## Final Verification Commands

Run these before pushing:

```bash
# 1. Search for API keys (should return NO results in lib/)
grep -r "AIzaSy" lib/

# 2. Search for Supabase URLs (should only be in .env.example)
grep -r "supabase.co" .

# 3. Check git status
git status

# 4. Review what will be committed
git diff --cached
```

## Push Commands

```bash
# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: SMS Transaction App"

# Add remote (replace with your repo URL)
git remote add origin YOUR_REPO_URL

# Push
git push -u origin main
```

## After Pushing

1. Visit your repository
2. Verify .env is NOT visible
3. Check that lib/core/env_config.dart has placeholders
4. Confirm README.md displays correctly
5. Test cloning and setup process

## If You Accidentally Pushed Credentials

1. Immediately rotate all exposed keys
2. Use git filter-branch or BFG Repo-Cleaner to remove from history
3. Force push cleaned history
4. Update all credentials
