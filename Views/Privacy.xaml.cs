using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class Privacy : ContentPage
{
    public Privacy(PrivacyViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
