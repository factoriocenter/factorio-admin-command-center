# Set the root project directory
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Ask the user where to save the output
$choice = Read-Host "Do you want to save the output in the current folder (Y), the parent folder (N), or a custom path (C)? [Y/N/C]"

switch ($choice.ToUpper()) {
    "Y" {
        $saveBase = $projectRoot
        break
    }
    "N" {
        $saveBase = Split-Path $projectRoot -Parent
        break
    }
    "C" {
        $customPath = Read-Host "Enter the full path where you want to save the output"
        $saveBase = $customPath
        break
    }
    default {
        Write-Host "Invalid option. Defaulting to current folder."
        $saveBase = $projectRoot
    }
}

# Use the root folder name as the output folder name
$rootFolderName = Split-Path $projectRoot -Leaf
$outputDir = Join-Path $saveBase "extraction_$rootFolderName"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Define the output Markdown file
$outputFile = Join-Path $outputDir 'extractedContent.md'

# Mapping of file extensions to language identifiers (for future validation)
$languageMap = @{
    '.php'        = 'php'
    '.js'         = 'javascript'
    '.ts'         = 'typescript'
    '.jsx'        = 'jsx'
    '.tsx'        = 'tsx'
    '.html'       = 'html'
    '.css'        = 'css'
    '.json'       = 'json'
    '.xml'        = 'xml'
    '.md'         = 'markdown'
    '.py'         = 'python'
    '.sh'         = 'bash'
    '.c'          = 'c'
    '.cpp'        = 'cpp'
    '.cs'         = 'csharp'
    '.java'       = 'java'
    '.lua'        = 'lua'
    '.rb'         = 'ruby'
    '.go'         = 'go'
    '.rs'         = 'rust'
    '.swift'      = 'swift'
    '.kt'         = 'kotlin'
    '.scala'      = 'scala'
    '.yml'        = 'yaml'
    '.yaml'       = 'yaml'
    '.ini'        = 'ini'
    '.env'        = ''
    '.txt'        = ''
    '.bat'        = 'batch'
    '.example'    = ''
    '.lock'       = ''
    '.toml'       = 'toml'
    '.dockerfile' = ''
    '.conf'       = ''
    '.cfg'        = ''
}

# Files without extensions that should always be included
$alwaysAllow = @(
    'Dockerfile',
    'Makefile',
    '.gitignore',
    '.prettierrc',
    '.editorconfig',
    '.gitattributes',
    '.eslintrc',
    '.babelrc'
)

# Remove old output file if it exists
if (Test-Path $outputFile) {
    try {
        Remove-Item $outputFile -Force
    } catch {
        Write-Host "Failed to delete the old file. Please close any program using it."
        exit
    }
}

# Recursively iterate through files in the project root
Get-ChildItem -Path $projectRoot -Recurse -File | ForEach-Object {
    $ext = $_.Extension.ToLower()
    $name = $_.Name

    # Determine if the file should be included
    $shouldInclude = $languageMap.ContainsKey($ext) -or ($alwaysAllow -contains $name)
    if (-not $shouldInclude) { return }

    # Read file content, handling errors
    try {
        $fileContent = Get-Content -Path $_.FullName -Raw
    } catch {
        $fileContent = '[ERROR READING FILE]'
    }

    # Append the file content to the Markdown output
    Add-Content -Path $outputFile -Value "### $name"
    Add-Content -Path $outputFile -Value '```'
    Add-Content -Path $outputFile -Value $fileContent
    Add-Content -Path $outputFile -Value '```'
    Add-Content -Path $outputFile -Value ''
}

Write-Host "`nMarkdown file successfully generated at:`n$outputFile"