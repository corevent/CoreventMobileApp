using System.Text;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CoreventApp.Services;

namespace CoreventApp.ViewModels;

public partial class PrivacyViewModel : ObservableObject
{
    private readonly IAuthService _authService;

    public PrivacyViewModel(IAuthService authService)
    {
        _authService = authService;
    }

    [RelayCommand]
    private async Task GoBack()
    {
        await Shell.Current.GoToAsync("..");
    }

    [RelayCommand]
    private async Task DownloadData()
    {
        var user = await _authService.GetCurrentUserAsync();

        var sb = new StringBuilder();
        sb.AppendLine("RESUMO DE DADOS LOCAIS - COREVENT");
        sb.AppendLine($"Data de geração: {DateTime.UtcNow.ToLocalTime():dd/MM/yyyy HH:mm}");
        sb.AppendLine("-----------------------------------");
        sb.AppendLine("");
        sb.AppendLine("DADOS DO PERFIL:");
        sb.AppendLine($"Nome: {user?.Name ?? "Não informado"}");
        sb.AppendLine($"E-mail: {user?.Email ?? "Não informado"}");
        sb.AppendLine("");
        sb.AppendLine("POLÍTICA DE PRIVACIDADE:");
        sb.AppendLine("O Corevent não coleta, armazena em nuvem ou compartilha seus dados.");
        sb.AppendLine("Todas as informações acima residem exclusivamente neste aparelho.");

        var fn = "meus_dados_corevent.txt";
        var file = Path.Combine(FileSystem.CacheDirectory, fn);
        await File.WriteAllTextAsync(file, sb.ToString());

        await Share.Default.RequestAsync(new ShareFileRequest
        {
            Title = "Baixar meus dados",
            File = new ShareFile(file)
        });
    }
}
