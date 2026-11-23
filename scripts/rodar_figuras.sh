#!/bin/bash
# Depois do job de dados (inclui DDR): formata o DDR, desenha todas as figuras e gera LEIAME/RELATORIO. Uso: sbatch --dependency=afterany:<jobid> ...
#SBATCH --job-name=esann_figuras
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=shared
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
set -uo pipefail
cd "${SLURM_SUBMIT_DIR:-$(pwd)}"
[ -f esann_figs/ddr_results.csv ] && python3 esann_materiais/make_ddr_v3.py
cd esann_materiais && Rscript make_figuras_v3.R > figuras_run_final.log 2>&1; cd ..
python3 esann_materiais/gerar_relatorio.py
echo "[$(date +%T)] fim"
