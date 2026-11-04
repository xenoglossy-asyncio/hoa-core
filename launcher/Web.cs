using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    static class Web
    {
        const int BufferSize = 81920;
        static readonly TimeSpan ProgressInterval = TimeSpan.FromMilliseconds(100);

        public static readonly HttpClient Client = CreateClient();

        static HttpClient CreateClient()
        {
            HttpClient client = new HttpClient { Timeout = Timeout.InfiniteTimeSpan };
            client.DefaultRequestHeaders.UserAgent.ParseAdd("HordesOfAzerothLauncher");
            return client;
        }

        public static async Task DownloadAsync(string url, string target, Action<long> report, CancellationToken cancel)
        {
            using (HttpResponseMessage response = await Client.GetAsync(url, HttpCompletionOption.ResponseHeadersRead, cancel))
            {
                response.EnsureSuccessStatusCode();
                using (Stream source = await response.Content.ReadAsStreamAsync(cancel))
                using (FileStream file = new FileStream(target, FileMode.Create, FileAccess.Write, FileShare.None, BufferSize, true))
                {
                    byte[] buffer = new byte[BufferSize];
                    long received = 0;
                    DateTime lastReport = DateTime.MinValue;
                    int read;
                    while ((read = await source.ReadAsync(buffer, 0, buffer.Length, cancel)) > 0)
                    {
                        await file.WriteAsync(buffer, 0, read, cancel);
                        received += read;
                        if (DateTime.UtcNow - lastReport >= ProgressInterval)
                        {
                            lastReport = DateTime.UtcNow;
                            report(received);
                        }
                    }
                    report(received);
                }
            }
        }

        public static string Describe(Exception e)
        {
            if (e is HttpRequestException http && http.StatusCode != null)
            {
                if (http.StatusCode == HttpStatusCode.NotFound)
                    return Loc.T("hoa.launcher.no_release_is_published_yet");
                return Loc.T("hoa.launcher.github_answered_with_an_error_0_try_again_in_a_moment", (int)http.StatusCode);
            }
            if (e is HttpRequestException || e is TaskCanceledException)
                return Loc.T("hoa.launcher.couldn_t_reach_github_check_your_connection_and_try_again");
            return Loc.T("hoa.launcher.the_release_information_couldn_t_be_read_try_again_in_a_mome");
        }

        public static bool IsProblem(Exception e) => e is HttpRequestException || e is TaskCanceledException;
    }
}
