# 🛸 Nave — O Navegador da OZATI

> **Nave** é a distribuição desktop de alta performance da OZATI construída sobre o núcleo aberto do Chromium. Sem telemetria do Google, sem conexões zumbis em segundo plano e com aceleração gráfica total por hardware.

---

## ⚡ Estrutura do Projeto

```
nave-browser/
├── assets/
│   ├── nave.ico          # Ícone oficial transparente multi-resolução
│   └── nave.svg          # Vetor SVG oficial da marca
├── bin/
│   └── engine/           # Motor Chromium x64 portátil limpo
├── installer/
│   └── nave_installer.iss# Script do Inno Setup para gerar o Nave-Setup.exe
├── profile_data/         # Perfil Local-First (dados e histórico isolados)
├── setup_nave_engine.ps1 # Script de setup e download em 1 clique
└── Nave.cmd              # Launcher oficial com flags de aceleração total
```

---

## 🏎️ Flags de Performance Ativadas por Padrão

* `--enable-gpu-rasterization`: Rasterização de página transferida integralmente para a GPU.
* `--enable-zero-copy`: Elimina gargalos de cópia de buffers entre memória RAM e VRAM.
* `--ignore-gpu-blocklist`: Habilita decodificação nativa por hardware em qualquer GPU compatível.
* `--enable-features=VaapiVideoDecoder,ParallelDownloading,CanvasOopRasterization`: Downloads divididos em pacotes paralelos e renderização de canvas fora da thread principal.
* `--disable-background-networking`: Zero pings e conexões de rastreamento para o Google.
* `--disable-sync`: Sem overhead de sincronização remota não solicitada.

---

## 🚀 Como gerar e rodar

1. **Baixar o motor e criar o atalho**:
   Execute no PowerShell:
   ```powershell
   .\setup_nave_engine.ps1
   ```
2. **Gerar o instalador final (`Nave-Setup.exe`)**:
   Abra o arquivo `installer/nave_installer.iss` no Inno Setup e clique em **Compile** (F9), ou execute via linha de comando.
