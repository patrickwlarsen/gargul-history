const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Check for silent flag
const args = process.argv.slice(2);
const silent = args.includes('--silent') || args.includes('-s');

function log(...messages) {
    if (!silent) {
        console.log(...messages);
    }
}

const scriptDir = __dirname;
const packagePath = path.join(scriptDir, 'package.json');
const sourcePath = path.join(scriptDir, 'Gargul_History');
const releasesDir = path.join(scriptDir, 'releases');
const archiveDir = path.join(scriptDir, 'archive');

// Read version from package.json
if (!fs.existsSync(packagePath)) {
    console.error('package.json not found');
    process.exit(1);
}

const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
const version = packageJson.version;

if (!version) {
    console.error('No version found in package.json');
    process.exit(1);
}

// Verify source exists
if (!fs.existsSync(sourcePath)) {
    console.error('Gargul_History folder not found');
    process.exit(1);
}

// Create directories if they don't exist
if (!fs.existsSync(archiveDir)) {
    fs.mkdirSync(archiveDir, { recursive: true });
}
if (!fs.existsSync(releasesDir)) {
    fs.mkdirSync(releasesDir, { recursive: true });
}

// Move existing releases to archive
const existingReleases = fs.readdirSync(releasesDir);
for (const file of existingReleases) {
    const srcFile = path.join(releasesDir, file);
    const destFile = path.join(archiveDir, file);
    if (fs.existsSync(destFile)) {
        fs.unlinkSync(destFile);
    }
    fs.renameSync(srcFile, destFile);
    log('Archived', file);
}

const zipName = `Gargul_History-v${version}.zip`;
const zipPath = path.join(releasesDir, zipName);

// Create zip using PowerShell (Windows) or zip command (Unix)
log('Creating', zipName);

if (process.platform === 'win32') {
    const psCommand = `Compress-Archive -Path "${sourcePath}" -DestinationPath "${zipPath}"`;
    execSync(`powershell -Command "${psCommand}"`, { stdio: 'inherit' });
} else {
    execSync(`zip -r "${zipPath}" Gargul_History`, { cwd: scriptDir, stdio: 'inherit' });
}

log('Build complete:', zipPath);
