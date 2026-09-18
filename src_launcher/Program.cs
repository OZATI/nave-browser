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
                
                // Procurar chrome.exe nos caminhos suportados
                string engineExe = Path.Combine(baseDir, "bin", "engine", "chrome.exe");
                if (!File.Exists(engineExe))
                {
                    engineExe = Path.Combine(baseDir, "engine", "chrome.exe");
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

                string profileDir = Path.Combine(baseDir, "profile_data");

                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = engineExe;
                
                string launchArgs = "--user-data-dir=\"" + profileDir + "\" " +
                    "--enable-gpu-rasterization " +
                    "--enable-zero-copy " +
                    "--ignore-gpu-blocklist " +
                    "--disable-background-networking " +
                    "--disable-component-update " +
                    "--disable-sync " +
                    "--metrics-recording-only " +
                    "--no-first-run " +
                    "--no-default-browser-check";

                if (args != null && args.Length > 0)
                {
                    launchArgs += " " + string.Join(" ", args);
                }

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
