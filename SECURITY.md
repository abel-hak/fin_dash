# Security Policy

## Sensitive Information

This repository does **NOT** contain any hardcoded credentials or API keys. All sensitive information must be configured locally.

### Required Credentials

Before running this application, you must provide:

1. **Supabase Credentials**
   - Project URL
   - Anon/Public Key
   - Get from: https://supabase.com/dashboard/project/_/settings/api

2. **Google Gemini API Key**
   - Free tier available
   - Get from: https://makersuite.google.com/app/apikey

### Configuration

Update `lib/core/env_config.dart` with your credentials:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

**⚠️ NEVER commit actual credentials to version control!**

### Protected Files

The following files are gitignored to prevent credential leaks:
- `.env`
- `*.env` (except `.env.example`)

### Reporting Security Issues

If you discover a security vulnerability, please email the maintainer directly instead of opening a public issue.

## Best Practices

1. **Never commit** `.env` files with real credentials
2. **Always use** `.env.example` as a template
3. **Rotate keys** if accidentally exposed
4. **Use environment variables** in production
5. **Keep dependencies updated** for security patches
