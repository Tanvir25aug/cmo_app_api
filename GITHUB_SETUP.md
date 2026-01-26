# Quick Start: Upload to GitHub

Follow these simple steps to upload your CMO API to GitHub.

## Step 1: Create GitHub Repository

1. Go to https://github.com and log in
2. Click the **"+"** icon (top right) → **"New repository"**
3. Fill in the details:
   - **Repository name**: `cmo-api`
   - **Description**: "CMO API - REST API for Change Meter Owner operations"
   - **Visibility**:
     - **Private** (recommended for production code)
     - Or **Public** (if open source)
   - **IMPORTANT**: Do NOT check "Initialize this repository with a README"
4. Click **"Create repository"**

## Step 2: Get Your Repository URL

After creating the repository, GitHub will show you a URL like:
```
https://github.com/YOUR_USERNAME/cmo-api.git
```

Copy this URL - you'll need it in the next step.

## Step 3: Upload Your Code

Open **Command Prompt** or **PowerShell** and run these commands:

```bash
# Navigate to your project folder
cd "D:\OTBL Project\cmo-api"

# Initialize Git repository
git init

# Add all files to Git
git add .

# Create your first commit
git commit -m "Initial commit: CMO API v1.0"

# Connect to GitHub (REPLACE with your actual repository URL)
git remote add origin https://github.com/YOUR_USERNAME/cmo-api.git

# Push code to GitHub
git branch -M main
git push -u origin main
```

**IMPORTANT**: Replace `YOUR_USERNAME` with your actual GitHub username in the `git remote add` command.

## Step 4: Enter GitHub Credentials

When you run `git push`, you'll be prompted to enter:
- **Username**: Your GitHub username
- **Password**: Use a **Personal Access Token** (not your password)

### How to Create Personal Access Token:

1. Go to GitHub → Click your profile picture → **Settings**
2. Scroll down to **Developer settings** → **Personal access tokens** → **Tokens (classic)**
3. Click **"Generate new token"** → **"Generate new token (classic)"**
4. Fill in:
   - **Note**: "CMO API Upload"
   - **Expiration**: Choose duration (e.g., 90 days)
   - **Scopes**: Check ✅ **repo** (Full control of private repositories)
5. Click **"Generate token"**
6. **COPY THE TOKEN** (you won't see it again!)
7. Use this token as your password when Git asks

## Step 5: Verify Upload

1. Go to your GitHub repository in browser
2. You should see all your files
3. **Note**: `.env` file will NOT be uploaded (it's in `.gitignore` for security)

## What Gets Uploaded vs What Doesn't

### ✅ WILL BE UPLOADED:
- Source code (`.js` files)
- Configuration files (`package.json`, `web.config`, etc.)
- `.env.example` (template)
- Documentation (`.md` files)
- Database scripts

### ❌ WILL NOT BE UPLOADED (in `.gitignore`):
- `.env` (contains sensitive data)
- `node_modules/` (dependencies)
- `uploads/` (uploaded files)
- `logs/` (log files)
- IDE files (`.vscode/`, `.idea/`)

## Future Updates

After initial upload, to push new changes:

```bash
# Check what changed
git status

# Add changed files
git add .

# Commit changes
git commit -m "Description of your changes"

# Push to GitHub
git push
```

## Troubleshooting

### Error: "remote origin already exists"
```bash
# Remove existing remote and add again
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/cmo-api.git
```

### Error: "failed to push some refs"
```bash
# Pull first, then push
git pull origin main --rebase
git push -u origin main
```

### Error: Authentication failed
- Make sure you're using a **Personal Access Token**, not your password
- Ensure token has **repo** permissions

## Clone Repository on Another Machine

To download your code on another computer (like your Windows Server):

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/cmo-api.git

# Navigate to folder
cd cmo-api

# Install dependencies
npm install

# Copy .env.example to .env and configure
copy .env.example .env
notepad .env
```

---

**Next Steps**: See `DEPLOYMENT.md` for Windows Server deployment instructions.
