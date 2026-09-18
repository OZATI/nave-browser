using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Win32;

namespace NaveBrowser
{
    static class Program
    {
        public const string CurrentVersion = "1.0.1";
        public const string VersionCheckUrl = "https://nave.ozati.co/version.json";

        private static volatile string s_pendingUpdateInstaller = null;

        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                // Suporte a TLS 1.2 para conexões seguras
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;

                // 0. Assegurar políticas corporativas do Windows para Google Search e Desativação da tela DMA
                EnsureSearchPolicies();

                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                
                // 1. Localizar executável do motor Chromium
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
                        "Motor do Nave não encontrado.\nCertifique-se de que a pasta 'bin/engine' está presente.",
                        "Nave Browser - Erro",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error
                    );
                    return;
                }

                // 2. Diretório de Perfil Isolado (Local-First)
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

                // 3. Extensões Nativas (Nave Core + Nave Theme)
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

                // 4. Flags de Performance, Google Search e Barra Lateral Moderna (Side Panel)
                string launchArgs = "--user-data-dir=\"" + profileDir + "\" " +
                    "--disable-search-engine-choice-screen " +
                    "--enable-gpu-rasterization " +
                    "--enable-zero-copy " +
                    "--ignore-gpu-blocklist " +
                    "--enable-features=SidePanel,SidePanelPinning,SideSearch,SidePanelCompanion,ChromeRefresh2023,ChromeWebuiRefresh2023,PowerBookmarks,VaapiVideoDecoder,ParallelDownloading,CanvasOopRasterization,BackForwardCache,Prerender2,HighEfficiencyModeAvailable " +
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

                Process browserProc = Process.Start(psi);

                // 5. Iniciar verificador de atualizações em segundo plano (5s e repete a cada 30min)
                System.Threading.Timer updateTimer = new System.Threading.Timer(
                    CheckForUpdatesCallback,
                    null,
                    5000,               // Primeira checagem 5s após abrir
                    30 * 60 * 1000      // Repete a cada 30 minutos enquanto o navegador estiver aberto
                );

                // Aguarda o usuário fechar o navegador
                if (browserProc != null)
                {
                    browserProc.WaitForExit();
                }

                // 6. Se baixou uma atualização pendente enquanto o navegador estava aberto,
                // aplica a atualização silenciosa exatamente agora que o navegador acabou de fechar!
                if (!string.IsNullOrEmpty(s_pendingUpdateInstaller) && File.Exists(s_pendingUpdateInstaller))
                {
                    try
                    {
                        ProcessStartInfo updatePsi = new ProcessStartInfo();
                        updatePsi.FileName = s_pendingUpdateInstaller;
                        updatePsi.Arguments = "/SILENT /CLOSEAPPLICATIONS";
                        updatePsi.UseShellExecute = true;
                        Process.Start(updatePsi);
                    }
                    catch { }
                }
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

        private static void EnsureSearchPolicies()
        {
            try
            {
                string[] policyKeys = new string[] {
                    @"Software\Policies\Chromium",
                    @"Software\Policies\Google\Chrome"
                };

                foreach (string keyPath in policyKeys)
                {
                    using (RegistryKey key = Registry.CurrentUser.CreateSubKey(keyPath))
                    {
                        if (key != null)
                        {
                            key.SetValue("DefaultSearchProviderEnabled", 1, RegistryValueKind.DWord);
                            key.SetValue("DefaultSearchProviderName", "Google", RegistryValueKind.String);
                            key.SetValue("DefaultSearchProviderSearchURL", "https://www.google.com/search?q={searchTerms}", RegistryValueKind.String);
                            key.SetValue("DefaultSearchProviderSuggestURL", "https://www.google.com/complete/search?client=chrome&q={searchTerms}", RegistryValueKind.String);
                            key.SetValue("DefaultSearchProviderIconURL", "https://www.google.com/favicon.ico", RegistryValueKind.String);
                            key.SetValue("DefaultSearchProviderKeyword", "google.com", RegistryValueKind.String);
                            key.SetValue("SearchEngineChoiceScreenEnabled", 0, RegistryValueKind.DWord);
                        }
                    }
                }
            }
            catch
            {
                // Silencioso se permissões forem restritas
            }
        }

        private static void CheckForUpdatesCallback(object state)
        {
            try
            {
                using (WebClient wc = new WebClient())
                {
                    wc.Headers.Add("User-Agent", "NaveBrowser/" + CurrentVersion);
                    string json = wc.DownloadString(VersionCheckUrl);

                    string remoteVersion = ExtractJsonValue(json, "version");
                    string downloadUrl = ExtractJsonValue(json, "download_url");

                    if (!string.IsNullOrEmpty(remoteVersion) && !string.IsNullOrEmpty(downloadUrl))
                    {
                        if (IsNewerVersion(remoteVersion, CurrentVersion))
                        {
                            string tempInstaller = Path.Combine(Path.GetTempPath(), "Nave-Setup-v" + remoteVersion + ".exe");

                            // Baixa em segundo plano silencioso se ainda não tiver baixado
                            if (!File.Exists(tempInstaller))
                            {
                                wc.DownloadFile(downloadUrl, tempInstaller);
                            }

                            if (File.Exists(tempInstaller))
                            {
                                s_pendingUpdateInstaller = tempInstaller;
                            }
                        }
                    }
                }
            }
            catch
            {
                // Silencioso caso esteja offline
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
