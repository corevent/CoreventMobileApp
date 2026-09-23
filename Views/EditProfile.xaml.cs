using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class EditProfile : ContentPage
{
    public EditProfile(EditProfileViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
