using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class Settings : ContentPage
{
    public Settings(SettingsViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
