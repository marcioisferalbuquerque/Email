#!/usr/bin/env bash
# Coleta, SOMENTE LEITURA, informações do BIOS/UEFI de um PC Intel no Linux.
# Não grava nada no firmware nem em variáveis UEFI.
# Uso:  bash coletar-bios-linux.sh          (dados básicos)
#       sudo bash coletar-bios-linux.sh     (dados completos)

set -u

SAIDA="bios-relatorio-$(hostname 2>/dev/null || echo pc)-$(date +%Y%m%d-%H%M).txt"
EFI_GLOBAL="8be4df61-93ca-11d2-aa0d-00e098032b8c"

secao() { printf '\n===== %s =====\n' "$1"; }
campo() { printf '%-32s %s\n' "$1:" "${2:-(indisponível)}"; }
ler()   { [ -r "$1" ] && tr -d '\0' < "$1" 2>/dev/null | head -c 300; }
tem()   { command -v "$1" >/dev/null 2>&1; }

# Último byte de uma variável UEFI (os 4 primeiros bytes são atributos).
efi_byte() {
    local f="/sys/firmware/efi/efivars/$1-$EFI_GLOBAL"
    [ -r "$f" ] && od -An -t u1 -j 4 -N 1 "$f" 2>/dev/null | tr -d ' '
}

{
echo "RELATÓRIO DE BIOS/UEFI (Linux) — gerado em $(date '+%Y-%m-%d %H:%M')"
echo "Executado como root: $([ "$(id -u)" -eq 0 ] && echo sim || echo 'não (alguns dados ficam indisponíveis)')"

secao "SISTEMA"
D=/sys/class/dmi/id
campo "Fabricante"            "$(ler $D/sys_vendor)"
campo "Modelo"                "$(ler $D/product_name)"
campo "Versão do produto"     "$(ler $D/product_version)"
campo "Placa-mãe (fabricante)" "$(ler $D/board_vendor)"
campo "Placa-mãe (modelo)"    "$(ler $D/board_name)"
campo "Kernel"                "$(uname -r)"
[ -r /etc/os-release ] && campo "Distribuição" "$(. /etc/os-release; echo "${PRETTY_NAME:-}")"

secao "BIOS"
campo "Fornecedor do BIOS"    "$(ler $D/bios_vendor)"
campo "Versão do BIOS"        "$(ler $D/bios_version)"
campo "Data do BIOS"          "$(ler $D/bios_date)"
if [ "$(id -u)" -eq 0 ] && tem dmidecode; then
    echo "--- dmidecode -t bios ---"
    dmidecode -t bios 2>/dev/null | grep -Ev '^\s*$|^#'
fi

secao "PROCESSADOR"
CPU_VENDOR=$(awk -F': ' '/^vendor_id/{print $2; exit}' /proc/cpuinfo)
campo "Fabricante da CPU"     "$CPU_VENDOR"
campo "Modelo da CPU"         "$(awk -F': ' '/^model name/{print $2; exit}' /proc/cpuinfo)"
campo "Família/modelo/stepping" "$(awk -F': ' '/^cpu family/{f=$2} /^model\t/{m=$2} /^stepping/{s=$2; print f"/"m"/"s; exit}' /proc/cpuinfo)"
campo "Microcódigo em uso"    "$(awk -F': ' '/^microcode/{print $2; exit}' /proc/cpuinfo)"
campo "Processadores lógicos" "$(grep -c '^processor' /proc/cpuinfo)"
campo "Núcleos físicos"       "$(awk -F': ' '/^core id/{print $2}' /proc/cpuinfo | sort -u | wc -l) (por soquete)"
[ "$CPU_VENDOR" != "GenuineIntel" ] && echo "AVISO: CPU não é Intel — o checklist Intel não se aplica integralmente."
grep -qw hypervisor /proc/cpuinfo && echo "AVISO: rodando dentro de MÁQUINA VIRTUAL — os dados refletem o hipervisor, não o BIOS físico."

secao "MODO DE BOOT E SECURE BOOT"
if [ -d /sys/firmware/efi ]; then
    campo "Modo de boot" "UEFI"
    SB=$(efi_byte SecureBoot); SM=$(efi_byte SetupMode)
    campo "SecureBoot (efivar)" "$([ "$SB" = 1 ] && echo ATIVADO || { [ "$SB" = 0 ] && echo DESATIVADO || echo '(indisponível)'; })"
    campo "SetupMode (efivar)"  "$([ "$SM" = 1 ] && echo '1 (sem chave PK — modo de configuração)' || { [ "$SM" = 0 ] && echo '0 (modo usuário)' || echo '(indisponível)'; })"
    tem mokutil && campo "mokutil --sb-state" "$(mokutil --sb-state 2>&1 | head -1)"
else
    campo "Modo de boot" "LEGACY/CSM (não UEFI)"
fi

secao "TPM"
if [ -e /sys/class/tpm/tpm0 ]; then
    campo "TPM presente" "sim"
    campo "Versão principal" "$(ler /sys/class/tpm/tpm0/tpm_version_major)"
    campo "Driver" "$(basename "$(readlink -f /sys/class/tpm/tpm0/device/driver 2>/dev/null)" 2>/dev/null)"
else
    campo "TPM presente" "não detectado (pode estar desativado no BIOS — Intel PTT)"
fi

secao "VIRTUALIZAÇÃO"
if grep -qw vmx /proc/cpuinfo; then
    campo "VT-x (flag vmx)" "presente"
else
    campo "VT-x (flag vmx)" "ausente (desativado no BIOS, CPU sem suporte ou máquina virtual)"
fi
if [ -e /sys/firmware/acpi/tables/DMAR ]; then
    campo "VT-d (tabela ACPI DMAR)" "presente — VT-d ativado no firmware"
else
    campo "VT-d (tabela ACPI DMAR)" "ausente — VT-d provavelmente desativado ou não suportado"
fi
campo "IOMMU em uso pelo kernel" "$(ls /sys/class/iommu 2>/dev/null | tr '\n' ' ')"

secao "VULNERABILIDADES DE CPU (visão do kernel)"
if [ -d /sys/devices/system/cpu/vulnerabilities ]; then
    for f in /sys/devices/system/cpu/vulnerabilities/*; do
        campo "$(basename "$f")" "$(ler "$f")"
    done
fi

secao "INTEL ME / THUNDERBOLT"
campo "Dispositivo MEI (/dev/mei0)" "$([ -e /dev/mei0 ] && echo presente || echo ausente)"
tem lspci && lspci 2>/dev/null | grep -iE 'MEI|HECI|Management Engine|Thunderbolt' | sed 's/^/  /'
for d in /sys/bus/thunderbolt/devices/domain*; do
    [ -e "$d/security" ] && campo "Thunderbolt $(basename "$d") segurança" "$(ler "$d/security")"
done

secao "MEMÓRIA"
campo "Total" "$(awk '/^MemTotal/{printf "%.1f GiB", $2/1048576}' /proc/meminfo)"
if [ "$(id -u)" -eq 0 ] && tem dmidecode; then
    dmidecode -t memory 2>/dev/null | grep -E '^\s*(Size|Speed|Configured Memory Speed|Manufacturer|Part Number):' | grep -v 'No Module' | sed 's/^\s*/  /'
fi

secao "ATUALIZAÇÕES DE FIRMWARE (fwupd/LVFS)"
if tem fwupdmgr; then
    echo "--- fwupdmgr get-devices ---"
    fwupdmgr get-devices </dev/null 2>&1 | head -80
    echo "--- fwupdmgr get-updates ---"
    fwupdmgr get-updates </dev/null 2>&1 | head -60
    echo "--- fwupdmgr security (HSI) ---"
    fwupdmgr security </dev/null 2>&1 | head -80
else
    echo "fwupd não instalado (opcional: instale o pacote 'fwupd' da sua distribuição)."
fi

echo
echo "FIM DO RELATÓRIO. Nenhuma configuração foi alterada."
} 2>&1 | tee "$SAIDA"

echo
echo "Relatório salvo em: $SAIDA"
