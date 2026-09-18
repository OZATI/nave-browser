using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Threading;
using System.Windows.Forms;

namespace NaveBrowser
{
    static class Program
    {
        public const string CurrentVersion = "1.0.0";
        public const string VersionCheckUrl = "https://nave.ozati.co/version.json";

        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                // Forçar suporte a TLS 1.2 para conexões HTTPS modernas
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;

                // 0. Iniciar verificação de atualizações em segundo plano (0ms de impacto no boot)
                ThreadPool.QueueUserWorkItem(CheckForUpdatesAsync);

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
                // Se instalado em Program Files / Programs, o perfil fica em LocalAppData/Nave/User Data
                string profileDir = Path.Combine(baseDir, "profile_data");
                if (baseDir.IndexOf("Programs", StringComparison.OrdinalIgnoreCase) >= 0 ||
                    baseDir.IndexOf("Program Files", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                    profileDir = Path.Combine(localAppData, "Nave", "User Data");
                }

                if (!Directory.Exists(profileDir))
                {
                    Directory.CreateDirectory(profileDir);
                }

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

        private static void CheckForUpdatesAsync(object state)
        {
            try
            {
                // Aguarda 5 segundos após abrir para nunca interferir na inicialização
                Thread.Sleep(5000);

                using (WebClient wc = new WebClient())
                {
                    wc.Headers.Add("User-Agent", "NaveBrowser/" + CurrentVersion);
                    string json = wc.DownloadString(VersionCheckUrl);

                    string remoteVersion = ExtractJsonValue(json, "version");
                    string downloadUrl = ExtractJsonValue(json, "download_url");
                    string notes = ExtractJsonValue(json, "notes");

                    if (!string.IsNullOrEmpty(remoteVersion) && !string.IsNullOrEmpty(downloadUrl))
                    {
                        if (IsNewerVersion(remoteVersion, CurrentVersion))
                        {
                            string tempInstaller = Path.Combine(Path.GetTempPath(), "Nave-Setup-v" + remoteVersion + ".exe");

                            // Baixar instalador em background
                            wc.DownloadFile(downloadUrl, tempInstaller);

                            if (File.Exists(tempInstaller))
                            {
                                string msg = "Uma nova versão do Nave (v" + remoteVersion + ") está disponível!\n\n" +
                                             (string.IsNullOrEmpty(notes) ? "" : "Novidades:\n" + notes + "\n\n") +
                                             "Deseja instalar a atualização agora em segundo plano?";

                                DialogResult dr = MessageBox.Show(
                                    msg,
                                    "Nave Browser - Atualização Disponível",
                                    MessageBoxButtons.YesNo,
                                    MessageBoxIcon.Information
                                );

                                if (dr == DialogResult.Yes)
                                {
                                    ProcessStartInfo updatePsi = new ProcessStartInfo();
                                    updatePsi.FileName = tempInstaller;
                                    updatePsi.Arguments = "/SILENT /CLOSEAPPLICATIONS";
                                    updatePsi.UseShellExecute = true;
                                    Process.Start(updatePsi);
                                }
                            }
                        }
                    }
                }
            }
            catch
            {
                // Silencioso se estiver offline
            }
        }

        private static string ExtractJsonValue(string json, string key)
        {
            try
            {
                string searchKey = "\"" + key + "\":";
                int idx = json.IndexOf(searchKey, StringComparison.OrdinalIgnoreCase);
                if (idx < 0) return "";
                int start = json.IndexOf("\"", idx + searchKey.Length);
                if (start < 0) return "";
                int end = json.IndexOf("\"", start + 1);
                if (end < 0) return "";
                return json.Substring(start + 1, end - start - 1);
            }
            catch
            {
                return "";
            }
        }

        private static bool IsNewerVersion(string remote, string local)
        {
            try
            {
                Version r = new Version(remote);
                Version l = new Version(local);
                return r > l;
            }
            catch
            {
                return false;
            }
        }
    }
}
