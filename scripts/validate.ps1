# Validation statique uniquement : aucun pull/build/up, aucun acces au moteur.
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Scratch = Join-Path $Root '.validation'
New-Item -ItemType Directory -Force -Path $Scratch | Out-Null
$OldDockerConfig = $env:DOCKER_CONFIG
$env:DOCKER_CONFIG = Join-Path $Scratch 'docker'
New-Item -ItemType Directory -Force -Path $env:DOCKER_CONFIG | Out-Null
try {
    foreach ($Stack in @('portainer','agent','minecraft','postgres','web','datalab')) {
        $EnvFile = Join-Path $Scratch "$Stack.env"
        $Values = Get-Content -Raw -LiteralPath (Join-Path $Root "compose/$Stack/.env.example")
        $Values = $Values -replace '(?m)^AGENT_SECRET=$','AGENT_SECRET=validation-only'
        $Values = $Values -replace '(?m)^POSTGRES_PASSWORD=$','POSTGRES_PASSWORD=validation-only'
        $Values = $Values -replace '(?m)^PGADMIN_PASSWORD=$','PGADMIN_PASSWORD=validation-only'
        $Values = $Values -replace '(?m)^JUPYTER_TOKEN=$','JUPYTER_TOKEN=validation-only'
        [IO.File]::WriteAllText($EnvFile, $Values)
        $ArgsBase = @('compose','-p',"validation-$Stack",'--env-file',$EnvFile,'-f',(Join-Path $Root "compose/$Stack/compose.yaml"))
        & docker @ArgsBase config --quiet
        if ($LASTEXITCODE -ne 0) { throw "Compose invalide : $Stack" }
        if ($Stack -eq 'web') {
            & docker @ArgsBase -f (Join-Path $Root 'compose/web/compose.dev.yaml') config --quiet
            if ($LASTEXITCODE -ne 0) { throw 'Compose web dev invalide' }
        }
        if ($Stack -eq 'postgres') {
            & docker @ArgsBase --profile admin config --quiet
            if ($LASTEXITCODE -ne 0) { throw 'Compose pgAdmin invalide' }
        }
        Write-Output "OK $Stack"
    }
    $TemplateEnv = Join-Path $Scratch 'templates.env'
    [IO.File]::WriteAllText($TemplateEnv, "WEB_IMAGE=example/web:validation`nLAB_IMAGE=example/lab:validation`nJUPYTER_TOKEN=validation-only`nDATASETS_PATH=/tmp/datasets`nLAB_OUTPUT_PATH=/tmp/output`n")
    foreach ($Stack in @('web','datalab')) {
        & docker compose --env-file $TemplateEnv -f (Join-Path $Root "templates/portainer/$Stack.compose.yaml") config --quiet
        if ($LASTEXITCODE -ne 0) { throw "Modele Portainer invalide : $Stack" }
        Write-Output "OK modele Portainer $Stack"
    }
} finally {
    $env:DOCKER_CONFIG = $OldDockerConfig
}
