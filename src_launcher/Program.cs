using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Win32;

namespace NaveBrowser
{
    static class Program
    {
        public const string CurrentVersion = "1.0.2";
        public const string VersionCheckUrl = "https://nave.ozati.co/version.json";

        private static volatile string s_pendingUpdateInstaller = null;

        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                // Suporte a TLS 1.2 para conexões seguras
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;

                string baseDir = AppDomain.CurrentDomain.BaseDirectory;

                // 1. Diretório de Perfil Isolado (Local-First)
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

                // 2. Assegurar Google Search nativo diretamente no motor, banco SQLite e políticas do Windows
                EnsureGoogleSearchEngine(profileDir, baseDir);

                // 3. Localizar executável do motor Chromium
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

                // 4. Extensões Nativas (Nave Core + Nave Theme)
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

                // 5. Flags de Performance, Google Search e Barra Lateral Moderna (Side Panel)
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

                // 6. Iniciar verificador de atualizações em segundo plano (5s e repete a cada 30min)
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

                // 7. Se baixou uma atualização pendente enquanto o navegador estava aberto,
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

        private static void EnsureGoogleSearchEngine(string profileDir, string baseDir)
        {
            try
            {
                // A. Políticas do Registro do Windows (HKCU e HKLM)
                string[] policyKeys = new string[] {
                    @"Software\Policies\Chromium",
                    @"Software\Policies\Google\Chrome"
                };

                foreach (string keyPath in policyKeys)
                {
                    try
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
                                key.SetValue("SearchSuggestEnabled", 1, RegistryValueKind.DWord);
                                key.SetValue("SearchEngineChoiceScreenEnabled", 0, RegistryValueKind.DWord);
                            }
                        }
                    }
                    catch { }

                    try
                    {
                        using (RegistryKey key = Registry.LocalMachine.CreateSubKey(keyPath))
                        {
                            if (key != null)
                            {
                                key.SetValue("DefaultSearchProviderEnabled", 1, RegistryValueKind.DWord);
                                key.SetValue("DefaultSearchProviderName", "Google", RegistryValueKind.String);
                                key.SetValue("DefaultSearchProviderSearchURL", "https://www.google.com/search?q={searchTerms}", RegistryValueKind.String);
                                key.SetValue("DefaultSearchProviderSuggestURL", "https://www.google.com/complete/search?client=chrome&q={searchTerms}", RegistryValueKind.String);
                                key.SetValue("DefaultSearchProviderIconURL", "https://www.google.com/favicon.ico", RegistryValueKind.String);
                                key.SetValue("DefaultSearchProviderKeyword", "google.com", RegistryValueKind.String);
                                key.SetValue("SearchSuggestEnabled", 1, RegistryValueKind.DWord);
                                key.SetValue("SearchEngineChoiceScreenEnabled", 0, RegistryValueKind.DWord);
                            }
                        }
                    }
                    catch { }
                }

                // B. Injetar Google no Banco de Dados SQLite (Web Data) do Perfil
                string defaultDir = Path.Combine(profileDir, "Default");
                if (!Directory.Exists(defaultDir))
                {
                    Directory.CreateDirectory(defaultDir);
                }

                string webDataPath = Path.Combine(defaultDir, "Web Data");
                string sqliteExe = Path.Combine(baseDir, "bin", "sqlite3.exe");
                if (!File.Exists(sqliteExe))
                {
                    sqliteExe = Path.Combine(baseDir, "sqlite3.exe");
                }

                if (File.Exists(sqliteExe) && File.Exists(webDataPath))
                {
                    string sqlCmd = "INSERT OR REPLACE INTO keywords (id, short_name, keyword, favicon_url, url, safe_for_autoreplace, originating_url, date_created, usage_count, input_encodings, suggest_url, prepopulate_id, created_by_policy, last_modified, sync_guid, alternate_urls, image_url, search_url_post_params, suggest_url_post_params, image_url_post_params, new_tab_url, last_visited, created_from_play_api, is_active, starter_pack_id, enforced_by_policy, featured_by_policy) VALUES (100, 'Google', 'google.com', 'https://www.google.com/favicon.ico', 'https://www.google.com/search?q=%s', 0, '', 13350000000000000, 100, 'UTF-8', 'https://suggestqueries.google.com/complete/search?client=chrome&q=%s', 0, 0, 13350000000000000, 'ozati-google-search-provider-v1', '[\"https://www.google.com/#q=%s\",\"https://www.google.com/search#q=%s\"]', '', '', '', '', 'https://www.google.com/', 0, 0, 1, 0, 0, 0);";

                    ProcessStartInfo psi = new ProcessStartInfo();
                    psi.FileName = sqliteExe;
                    psi.Arguments = "\"" + webDataPath + "\" \"" + sqlCmd + "\"";
                    psi.CreateNoWindow = true;
                    psi.UseShellExecute = false;
                    using (Process p = Process.Start(psi))
                    {
                        if (p != null) p.WaitForExit(1500);
                    }
                }

                // C. Forçar Google Search no arquivo Preferences do Perfil
                string prefFile = Path.Combine(defaultDir, "Preferences");
                if (File.Exists(prefFile))
                {
                    string content = File.ReadAllText(prefFile, Encoding.UTF8);
                    if (!content.Contains("\"keyword\":\"google.com\"") && !content.Contains("\"keyword\": \"google.com\""))
                    {
                        string googleBlock = "\"default_search_provider\":{\"guid\":\"ozati-google-search-provider-v1\"},\"default_search_provider_data\":{\"template_url_data\":{\"short_name\":\"Google\",\"keyword\":\"google.com\",\"url\":\"https://www.google.com/search?q=%s\",\"suggestions_url\":\"https://suggestqueries.google.com/complete/search?client=chrome&q=%s\",\"favicon_url\":\"https://www.google.com/favicon.ico\",\"id\":\"100\",\"prepopulate_id\":0,\"safe_for_autoreplace\":false,\"is_default\":true,\"synced_guid\":\"ozati-google-search-provider-v1\"}}";
                        content = Regex.Replace(content, "\"default_search_provider_data\"\\s*:\\s*\\{[^}]*\\{[^}]*\\}[^}]*\\}", googleBlock);
                        content = Regex.Replace(content, "\"search_engine_choice_screen_profile_init_condition\"\\s*:\\s*\\d+", "\"search_engine_choice_screen_profile_init_condition\":0");
                        File.WriteAllText(prefFile, content, Encoding.UTF8);
                    }
                }
            }
            catch
            {
                // Silencioso se o perfil estiver em uso exclusivo temporário
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


