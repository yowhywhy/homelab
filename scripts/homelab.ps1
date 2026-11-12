param(
    [Parameter(Position=0)][ValidateSet('list','init','config','up','down','logs','update','backup','restore')][string]$Action = 'list',
    [Parameter(Position=1)][ValidateSet('portainer','agent','minecraft','postgres','web','datalab')][string]$Stack,
    [string]$Instance,
    [switch]$Dev,
    [switch]$Admin,
    [string]$File
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Stacks = @('portainer','agent','minecraft','postgres','web','datalab')
if ($Action -eq 'list') { $Stacks; exit 0 }
if (!$Stack) { throw 'Indiquer une stack. Exemple : .\scripts\homelab.ps1 init postgres' }
if (!$Instance) { $Instance = $Stack }
if ($Instance -cnotmatch '^[a-z0-9][a-z0-9_-]*$') { throw 'Instance : minuscules, chiffres, tirets et underscores uniquement.' }
if ($Dev -and $Stack -ne 'web') { throw '-Dev exige web.' }
if ($Admin -and $Stack -ne 'postgres') { throw '-Admin exige postgres.' }
$EnvFile = Join-Path $Root "config/$Instance.env"
if ($Action -eq 'init') {
    if (Test-Path -LiteralPath $EnvFile) { throw "Configuration deja presente : $EnvFile" }
    Copy-Item -LiteralPath (Join-Path $Root "compose/$Stack/.env.example") -Destination $EnvFile
    Write-Output "Configurer $EnvFile avant demarrage."
    exit 0
}
if (!(Test-Path -LiteralPath $EnvFile)) { throw "Executer init $Stack avec la meme instance auparavant." }
$ComposeArgs = @('compose','--project-name',"homelab-$Instance",'--env-file',$EnvFile,'-f',(Join-Path $Root "compose/$Stack/compose.yaml"))
if ($Dev) { $ComposeArgs += @('-f',(Join-Path $Root 'compose/web/compose.dev.yaml')) }
if ($Admin) { $ComposeArgs += @('--profile','admin') }
function Invoke-Compose([string[]]$CommandArgs) {
    & docker @ComposeArgs @CommandArgs
    if ($LASTEXITCODE -ne 0) { throw "Docker Compose a echoue (code $LASTEXITCODE)." }
}
switch ($Action) {
    config { Invoke-Compose @('config','--quiet') }
    up { Invoke-Compose @('up','-d','--build','--remove-orphans') }
    down { Invoke-Compose @('down') }
    logs { Invoke-Compose @('logs','--follow','--tail','100') }
    update {
        # Les images locales web/lab sont reconstruites, les autres sont tirees.
        if ($Stack -notin @('web','datalab')) { Invoke-Compose @('pull') }
        else { Invoke-Compose @('build','--pull') }
        Invoke-Compose @('up','-d','--remove-orphans')
    }
    { $_ -in 'backup','restore' } {
        if ($Stack -ne 'postgres') { throw 'backup/restore exigent postgres.' }
        if (!$File) {
            if ($Action -eq 'restore') { throw '-File est obligatoire pour restore.' }
            $File = "$Instance-$(Get-Date -Format 'yyyyMMdd-HHmmss').dump"
        }
        if ($File -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_.-]*\.(sql|dump|backup)$') { throw 'File doit etre un nom simple .sql, .dump ou .backup, sans chemin.' }
        $Sql = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot "postgres-$Action.sh")
        # Base64 evite la perte des guillemets par le passage natif PowerShell 5.1.
        # Le nom de fichier est borne a un alphabet sans caracteres de shell.
        $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($Sql -replace "`r`n", "`n")))
        $Command = "printf %s $Encoded | base64 -d | sh -s -- $File"
        Invoke-Compose @('exec','-T','postgres','sh','-ec',$Command)
    }
}
