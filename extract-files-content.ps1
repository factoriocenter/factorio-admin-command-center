$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$desktopPath = [Environment]::GetFolderPath('Desktop')

# Usa o nome da pasta raiz como nome de saída
$rootFolderName = Split-Path $projectRoot -Leaf
$outputDir = Join-Path $desktopPath "extracao_$rootFolderName"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$outputFile = Join-Path $outputDir 'conteudoExtraido.md'

# Mapeamento de extensão (sem uso direto, mas serve pra validação futura)
$languageMap = @{
    '.php' = 'php'
    '.js' = 'javascript'
    '.ts' = 'typescript'
    '.jsx' = 'jsx'
    '.tsx' = 'tsx'
    '.html' = 'html'
    '.css' = 'css'
    '.json' = 'json'
    '.xml' = 'xml'
    '.md' = 'markdown'
    '.py' = 'python'
    '.sh' = 'bash'
    '.c' = 'c'
    '.cpp' = 'cpp'
    '.cs' = 'csharp'
    '.java' = 'java'
    '.lua' = 'lua'
    '.rb' = 'ruby'
    '.go' = 'go'
    '.rs' = 'rust'
    '.swift' = 'swift'
    '.kt' = 'kotlin'
    '.scala' = 'scala'
    '.yml' = 'yaml'
    '.yaml' = 'yaml'
    '.ini' = 'ini'
    '.env' = ''
    '.txt' = ''
    '.bat' = 'batch'
    '.example' = ''
    '.lock' = ''
    '.toml' = 'toml'
    '.dockerfile' = ''
    '.conf' = ''
    '.cfg' = ''
}

# Arquivos SEM EXTENSÃO que devem ser sempre incluídos
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

# Remove arquivo antigo se existir
if (Test-Path $outputFile) {
    try {
        Remove-Item $outputFile -Force
    } catch {
        Write-Host "Falha ao apagar o arquivo antigo. Feche qualquer app que esteja usando ele."
        exit
    }
}

Get-ChildItem -Path $projectRoot -Recurse -File | ForEach-Object {
    $ext = $_.Extension.ToLower()
    $name = $_.Name

    $deveIncluir = $languageMap.ContainsKey($ext) -or ($alwaysAllow -contains $name)
    if (-not $deveIncluir) { return }

    try {
        $fileContent = Get-Content -Path $_.FullName -Raw
    } catch {
        $fileContent = '[ERRO AO LER O ARQUIVO]'
    }

    Add-Content -Path $outputFile -Value "### $name"
    Add-Content -Path $outputFile -Value '```'
    Add-Content -Path $outputFile -Value $fileContent
    Add-Content -Path $outputFile -Value '```'
    Add-Content -Path $outputFile -Value ''
}

Write-Host ''
Write-Host 'Arquivo Markdown gerado com sucesso em:'
Write-Host $outputFile
