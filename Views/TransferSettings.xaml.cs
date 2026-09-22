using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class TransferSettings : ContentPage
{
    public TransferSettings(TransferSettingsViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
