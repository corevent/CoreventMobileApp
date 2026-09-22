using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class Profile : ContentPage
{
    public Profile(ProfileViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
