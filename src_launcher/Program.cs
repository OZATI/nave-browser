using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

namespace NaveBrowser
{
    static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                
                // 1. Localizar executável do motor Chromium (portátil ou instalado)
                string engineExe = Path.Combine(baseDir, "bin", "engine", "chrome.exe");
                if (!File.Exists(engineExe))
                {
                    engineExe = Path.Combine(baseDir, "engine", "chrome.exe");
                }
                if (!File.Exists(engineExe))
                {
                    engineExe = Path.Combine(baseDir, "chrome.exe");
                }

                if (!File.Exists(engineExe))
                {
                    MessageBox.Show(
                        "Motor do Nave não encontrado.\nCertifique-se de que a pasta 'bin/engine' ou 'engine' está presente.",
                        "Nave Browser - Erro de Inicialização",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error
                    );
                    return;
                }

                // 2. Diretório de Perfil Isolado (Local-First, sem telemetria Google)
                string profileDir = Path.Combine(baseDir, "profile_data");

                // 3. Carregamento das Extensões Nativas (Nave Shield + Nave Dark Theme)
                string coreExt = Path.Combine(baseDir, "extensions", "nave_core");
                string themeExt = Path.Combine(baseDir, "extensions", "nave_theme");
                string extArg = "";

                if (Directory.Exists(coreExt) && Directory.Exists(themeExt))
                {
                    extArg = " --load-extension=\"" + coreExt + "," + themeExt + "\"";
                }
                else if (Directory.Exists(coreExt))
                {
                    extArg = " --load-extension=\"" + coreExt + "\"";
                }

                // 4. Flags de Performance Equivalentes e Superiores ao Brave + Identidade Nave
                string launchArgs = "--user-data-dir=\"" + profileDir + "\" " +
                    "--app-id=\"OZATI.Nave\" " +
                    "--class=\"OZATI.Nave\" " +
                    "--enable-gpu-rasterization " +
                    "--enable-zero-copy " +
                    "--ignore-gpu-blocklist " +
                    "--enable-features=VaapiVideoDecoder,ParallelDownloading,CanvasOopRasterization,BackForwardCache,Prerender2,HighEfficiencyModeAvailable " +
                    "--disable-background-networking " +
                    "--disable-domain-reliability " +
                    "--disable-component-update " +
                    "--disable-sync " +
                    "--disable-breakpad " +
                    "--disable-logging " +
                    "--metrics-recording-only " +
                    "--no-first-run " +
                    "--no-default-browser-check " +
                    "--force-dark-mode " +
                    "--disk-cache-size=1073741824" +
                    extArg;

                if (args != null && args.Length > 0)
                {
                    launchArgs += " " + string.Join(" ", args);
                }

                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = engineExe;
                psi.Arguments = launchArgs;
                psi.UseShellExecute = false;

                Process.Start(psi);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "Falha ao iniciar o Nave:\n" + ex.Message,
                    "Nave Browser",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
            }
        }
    }
}
