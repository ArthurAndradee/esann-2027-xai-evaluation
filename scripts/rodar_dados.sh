#!/bin/bash
# Gera todos os dados do prompt v3 (CPU). Uso: sbatch esann_materiais/rodar_dados.sh  (da raiz do repositório)
#SBATCH --job-name=esann_dados
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=shared
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=06:00:00
set -uo pipefail
cd "${SLURM_SUBMIT_DIR:-$(pwd)}"
mkdir -p esann_materiais/dados
ok() { echo "[$(date +%T)] $1"; }
python3 esann_materiais/make_dados_v3.py && ok "dados ok" || ok "FALHOU dados"
( python3 esann_figs/make_ddr.py > esann_figs/make_ddr_run.log 2>&1 && python3 esann_materiais/make_ddr_v3.py && ok "ddr ok" ) || ok "FALHOU ddr" &
~/.venvs/tf213-cpu/bin/python esann_materiais/make_paineis_v3.py && ok "paineis ok" || ok "FALHOU paineis"
wait
ok "fim dos dados"
