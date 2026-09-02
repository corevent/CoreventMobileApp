param (
    [switch]$NoReport = $false,
    [switch]$OpenReport = $false
)

$ErrorActionPreference = "Stop"

Write-Host "Restaurando ferramentas locais do .NET..." -ForegroundColor Cyan
dotnet tool restore

Write-Host "`nExecutando testes com coleta de cobertura..." -ForegroundColor Cyan
$testResultDir = Join-Path $PSScriptRoot "..\TestResults"
$runSettingsPath = Join-Path $PSScriptRoot "..\tests\CoreventApp.UnitTests\coverlet.runsettings"

if (Test-Path $testResultDir) {
    Remove-Item $testResultDir -Recurse -Force
}

$testProj = Join-Path $PSScriptRoot "..\tests\CoreventApp.UnitTests\CoreventApp.UnitTests.csproj"

dotnet test $testProj `
    --configuration Debug `
    --settings $runSettingsPath `
    --collect:"XPlat Code Coverage" `
    --results-directory $testResultDir `
    --logger "console;verbosity=normal"

if (-not $NoReport) {
    Write-Host "`nGerando relatorio de cobertura HTML com ReportGenerator..." -ForegroundColor Cyan
    $coverageReportDir = Join-Path $testResultDir "CoverageReport"
    $coverageFiles = Get-ChildItem -Path $testResultDir -Filter "coverage.cobertura.xml" -Recurse | Select-Object -ExpandProperty FullName

    if ($coverageFiles) {
        dotnet reportgenerator `
            "-reports:$coverageFiles" `
            "-targetdir:$coverageReportDir" `
            "-reporttypes:Html;TextSummary;Cobertura" `
            "-assemblyfilters:-*.UnitTests;-ZXing*;-AathifMahir*;-Microsoft*;-System*"

        Write-Host "`n================== RESUMO DE COBERTURA ==================" -ForegroundColor Green
        $summaryPath = Join-Path $coverageReportDir "Summary.txt"
        if (Test-Path $summaryPath) {
            Get-Content $summaryPath
        }

        Write-Host "`nRelatorio HTML gerado em: $coverageReportDir\index.html" -ForegroundColor Green
        if ($OpenReport) {
            Start-Process (Join-Path $coverageReportDir "index.html")
        }
    } else {
        Write-Warning "Nenhum arquivo coverage.cobertura.xml foi encontrado."
    }
}
