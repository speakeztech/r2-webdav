# Project Structure

```
r2-webdav-multiuser/
├── src/
│   └── index.ts                # Main Worker code (no hardcoded users)
├── .editorconfig              # Editor configuration
├── .gitignore                 # Git ignore patterns
├── .prettierrc                # Code formatting config
├── package.json               # Node dependencies
├── tsconfig.json              # TypeScript configuration  
├── wrangler.toml              # Cloudflare Worker config
├── README.md                  # Documentation
├── add-user.ps1               # Add user PowerShell script
├── remove-user.ps1            # Remove user PowerShell script
├── list-users.ps1             # List users PowerShell script
└── deploy.ps1                 # Deploy worker PowerShell script
```

## Key Design Principles

1. **No hardcoded users** - All users managed via PowerShell CLI
2. **Secrets for passwords** - Using `wrangler secret put`
3. **Deterministic naming** - Username determines all resource names
4. **Dynamic access** - Worker accesses resources by name
5. **Professional structure** - Proper separation of concerns

## How It Works

### Adding Users
```powershell
.\add-user.ps1 -Username alice -Password mypassword
```

This:
1. Creates R2 bucket: `alice-webdav-sync`
2. Stores password as secret: `USER_ALICE_PASSWORD`
3. Adds binding to `wrangler.toml`: `alice_webdav_sync`
4. Deploy to activate

### Runtime Flow
1. User authenticates with username/password
2. Worker constructs deterministic names from username
3. Worker retrieves password from secret `USER_<USERNAME>_PASSWORD`
4. Worker accesses R2 bucket via binding `<username>_webdav_sync`
5. All WebDAV operations routed to user's bucket

## PowerShell Scripts

### add-user.ps1
- Validates username (alphanumeric + underscore)
- Creates R2 bucket with deterministic name
- Stores password in Cloudflare Secrets
- Appends bucket binding to wrangler.toml

### remove-user.ps1
- Deletes user's R2 bucket
- Deletes password secret
- Manual cleanup of wrangler.toml required

### list-users.ps1
- Lists all configured users by parsing secrets
- Shows bucket names for each user

### deploy.ps1
- Deploys the worker to Cloudflare
- Shows the worker URL after deployment

## Security Features

- **No passwords in code** - All in Cloudflare Secrets
- **Timing-safe comparison** - Prevents timing attacks
- **Complete isolation** - Each user has separate bucket
- **No user enumeration** - Failed auth doesn't reveal if user exists
- **Professional error handling** - Consistent error responses

## Why This Architecture?

1. **Simple** - Username determines everything
2. **Secure** - Proper secret management
3. **Scalable** - Add users without code changes
4. **Maintainable** - Clear separation of concerns
5. **Professional** - Uses platform features correctly

## Example Workflow

```powershell
# Add a new user
.\add-user.ps1 -Username jsmith -Password "secure123"

# Deploy the changes
.\deploy.ps1

# List all users
.\list-users.ps1

# Remove a user
.\remove-user.ps1 -Username jsmith
```

The worker code never changes - it just uses deterministic naming to find the right resources for each user.