using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;

[assembly: AssemblyTitle("4KMPV")]
[assembly: AssemblyDescription("Portable 4K media player with Anime4K")]
[assembly: AssemblyCompany("Shiro Player")]
[assembly: AssemblyProduct("4KMPV Portable")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

internal static class Program
{
    private static string Quote(string value)
    {
        if (value.Length > 0 && value.IndexOfAny(new[] {' ', '\t', '"'}) < 0) return value;
        var result = new StringBuilder("\"");
        var slashes = 0;
        foreach (var character in value)
        {
            if (character == '\\') { slashes++; continue; }
            if (character == '"') result.Append('\\', slashes * 2 + 1);
            else result.Append('\\', slashes);
            slashes = 0;
            result.Append(character);
        }
        result.Append('\\', slashes * 2).Append('"');
        return result.ToString();
    }

    [STAThread]
    private static int Main(string[] args)
    {
        var root = AppDomain.CurrentDomain.BaseDirectory;
        var player = Path.Combine(root, "mpv.exe");
        if (!File.Exists(player)) return 2;

        var arguments = new StringBuilder();
        foreach (var argument in args)
        {
            if (arguments.Length > 0) arguments.Append(' ');
            arguments.Append(Quote(argument));
        }

        Process.Start(new ProcessStartInfo
        {
            FileName = player,
            Arguments = arguments.ToString(),
            WorkingDirectory = root,
            UseShellExecute = false,
        });
        return 0;
    }
}
