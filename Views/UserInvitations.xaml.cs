using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class UserInvitations : ContentPage
{
    public UserInvitations(UserInvitationsViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
