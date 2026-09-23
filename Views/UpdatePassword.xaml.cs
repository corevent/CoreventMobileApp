using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class UpdatePassword : ContentPage
{
    public UpdatePassword(UpdatePasswordViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
