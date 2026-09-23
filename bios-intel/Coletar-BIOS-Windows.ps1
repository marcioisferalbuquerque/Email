<#
  Coleta, SOMENTE LEITURA, informações do BIOS/UEFI de um PC Intel no Windows.
  Não grava nada no firmware, não altera BitLocker, TPM nem Secure Boot.

  Uso (PowerShell como Administrador, na pasta deste arquivo):
      powershell -ExecutionPolicy Bypass -File .\Coletar-BIOS-Windows.ps1

  Gera "bios-relatorio-<computador>-<data>.txt" na Área de Trabalho.
#>

$ErrorActionPreference = 'SilentlyContinue'
$saida = Join-Path ([Environment]::GetFolderPath('Desktop')) ("bios-relatorio-{0}-{1}.txt" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd-HHmm'))
$linhas = New-Object System.Collections.Generic.List[string]

function Secao($t) { $linhas.Add(''); $linhas.Add("===== $t =====") }
function Campo($n, $v) {
    if ($null -eq $v -or "$v" -eq '') { $v = '(indisponível)' }
    $linhas.Add(('{0,-34} {1}' -f ($n + ':'), $v))
}
function Lista($arr) { if ($arr) { ($arr | ForEach-Object { "$_" }) -join ', ' } }

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$linhas.Add("RELATÓRIO DE BIOS/UEFI (Windows) — gerado em $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$linhas.Add("Executado como Administrador: $(if ($admin) {'sim'} else {'NÃO — Secure Boot, TPM e BitLocker ficam indisponíveis'})")

# ---------------- Sistema ----------------
$cs   = Get-CimInstance Win32_ComputerSystem
$os   = Get-CimInstance Win32_OperatingSystem
$bb   = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS

Secao 'SISTEMA'
Campo 'Fabricante'              $cs.Manufacturer
Campo 'Modelo'                  $cs.Model
Campo 'Família do sistema'      $cs.SystemFamily
Campo 'Placa-mãe (fabricante)'  $bb.Manufacturer
Campo 'Placa-mãe (modelo)'      $bb.Product
Campo 'Windows'                 ("{0} {1} (build {2})" -f $os.Caption, $os.OSArchitecture, $os.BuildNumber)
Campo 'Hipervisor em execução'  $cs.HypervisorPresent

# ---------------- BIOS ----------------
Secao 'BIOS'
Campo 'Fornecedor do BIOS'      $bios.Manufacturer
Campo 'Versão do BIOS'          $bios.SMBIOSBIOSVersion
Campo 'Versão (texto)'          (Lista $bios.BIOSVersion)
Campo 'Data do BIOS'            $(if ($bios.ReleaseDate) { $bios.ReleaseDate.ToString('yyyy-MM-dd') })
Campo 'Versão SMBIOS'           ("{0}.{1}" -f $bios.SMBIOSMajorVersion, $bios.SMBIOSMinorVersion)
Campo 'Versão do firmware EC'   $(if ($bios.EmbeddedControllerMajorVersion -ne 255) { "{0}.{1}" -f $bios.EmbeddedControllerMajorVersion, $bios.EmbeddedControllerMinorVersion })

# ---------------- Processador ----------------
Secao 'PROCESSADOR'
foreach ($cpu in Get-CimInstance Win32_Processor) {
    Campo 'Fabricante da CPU'        $cpu.Manufacturer
    Campo 'Modelo da CPU'            $cpu.Name.Trim()
    Campo 'Núcleos / lógicos'        ("{0} / {1}" -f $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors)
    Campo 'Hyper-Threading ativo'    ($cpu.NumberOfLogicalProcessors -gt $cpu.NumberOfCores)
    Campo 'VT-x suportado pela CPU'  $cpu.VMMonitorModeExtensions
    Campo 'VT-x ativado no firmware' $(if ($cs.HypervisorPresent) { 'hipervisor em execução — logo VT-x está ativado' } else { $cpu.VirtualizationFirmwareEnabled })
    Campo 'SLAT (EPT)'               $cpu.SecondLevelAddressTranslationExtensions
    if ($cpu.Manufacturer -ne 'GenuineIntel') { $linhas.Add('AVISO: CPU não é Intel — o checklist Intel não se aplica integralmente.') }
}

# ---------------- Boot / Secure Boot ----------------
Secao 'MODO DE BOOT E SECURE BOOT'
Campo 'Tipo de firmware ($env:firmware_type)' $env:firmware_type
if ($admin) {
    try {
        $sb = Confirm-SecureBootUEFI -ErrorAction Stop
        Campo 'Secure Boot' $(if ($sb) { 'ATIVADO' } else { 'DESATIVADO' })
    } catch {
        Campo 'Secure Boot' ("não suportado/indisponível ({0})" -f $_.Exception.Message)
    }
} else { Campo 'Secure Boot' '(requer Administrador)' }

# ---------------- TPM ----------------
Secao 'TPM'
$tpm = Get-CimInstance -Namespace 'root/cimv2/Security/MicrosoftTpm' -ClassName Win32_Tpm
if ($tpm) {
    Campo 'TPM presente'             'sim'
    Campo 'Fabricante (INTC = Intel PTT)' $tpm.ManufacturerIdTxt
    Campo 'Versão da especificação'  $tpm.SpecVersion
    Campo 'Ativado'                  $tpm.IsEnabled_InitialValue
    Campo 'Ativo (activated)'        $tpm.IsActivated_InitialValue
} elseif ($admin) {
    Campo 'TPM presente' 'não detectado (pode estar desativado no BIOS — Intel PTT)'
} else { Campo 'TPM' '(requer Administrador)' }

# ---------------- VBS / Integridade de memória ----------------
Secao 'SEGURANÇA BASEADA EM VIRTUALIZAÇÃO (Win32_DeviceGuard)'
$dg = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard
if ($dg) {
    $propNomes = @{ 1='Hipervisor'; 2='Secure Boot'; 3='Proteção DMA (VT-d)'; 4='Secure Memory Overwrite'; 5='NX'; 6='Mitigações SMM'; 7='MBEC/GMET'; 8='Virtualização APIC' }
    $svcNomes  = @{ 1='Credential Guard'; 2='Integridade de memória (HVCI)'; 3='System Guard Secure Launch'; 4='SMM Firmware Measurement'; 5='Proteção de pilha em modo kernel'; 6='Proteção de pilha (auditoria)'; 7='Hypervisor-Enforced Paging Translation' }
    $vbs = @{ 0='não habilitada'; 1='habilitada mas não em execução'; 2='habilitada e em execução' }
    Campo 'VBS'                         $vbs[[int]$dg.VirtualizationBasedSecurityStatus]
    Campo 'Recursos disponíveis'        (Lista ($dg.AvailableSecurityProperties | Where-Object { $_ -ne 0 } | ForEach-Object { "$_=$($propNomes[[int]$_])" }))
    Campo 'Serviços em execução'        (Lista ($dg.SecurityServicesRunning | Where-Object { $_ -ne 0 } | ForEach-Object { "$_=$($svcNomes[[int]$_])" }))
    $linhas.Add('  (valores conforme learn.microsoft.com — "Enable memory integrity", seção Win32_DeviceGuard)')
} else { Campo 'Win32_DeviceGuard' '(indisponível)' }

# ---------------- BitLocker ----------------
Secao 'BITLOCKER (importante antes de atualizar o BIOS)'
if ($admin) {
    $vols = Get-BitLockerVolume
    if ($vols) {
        foreach ($v in $vols) {
            Campo ("Volume {0}" -f $v.MountPoint) ("proteção: {0}; status: {1}" -f $v.ProtectionStatus, $v.VolumeStatus)
        }
    } else { Campo 'BitLocker' 'nenhum volume retornado (recurso ausente ou não usado)' }
} else { Campo 'BitLocker' '(requer Administrador)' }

# ---------------- Intel ME / Thunderbolt ----------------
Secao 'INTEL ME / THUNDERBOLT'
$me = Get-PnpDevice -PresentOnly | Where-Object { $_.FriendlyName -match 'Management Engine|MEI' }
Campo 'Intel ME (driver MEI)' $(if ($me) { Lista ($me | ForEach-Object { "$($_.FriendlyName) [$($_.Status)]" }) } else { 'não encontrado' })
$tb = Get-PnpDevice -PresentOnly | Where-Object { $_.FriendlyName -match 'Thunderbolt|USB4' }
Campo 'Thunderbolt/USB4' $(if ($tb) { Lista ($tb | Select-Object -ExpandProperty FriendlyName -Unique) } else { 'não encontrado' })

# ---------------- Memória ----------------
Secao 'MEMÓRIA'
foreach ($m in Get-CimInstance Win32_PhysicalMemory) {
    Campo ("Pente {0}" -f $m.DeviceLocator) ("{0} GB; nominal {1} MT/s; configurada {2} MT/s; {3} {4}" -f [math]::Round($m.Capacity/1GB), $m.Speed, $m.ConfiguredClockSpeed, $m.Manufacturer, "$($m.PartNumber)".Trim())
}
$linhas.Add('  (se "configurada" < "nominal", o perfil XMP pode estar desativado — ver recomendações)')

$linhas.Add('')
$linhas.Add('FIM DO RELATÓRIO. Nenhuma configuração foi alterada.')

$linhas | Set-Content -Path $saida -Encoding UTF8
$linhas | ForEach-Object { Write-Host $_ }
Write-Host ''
Write-Host "Relatório salvo em: $saida" -ForegroundColor Green
