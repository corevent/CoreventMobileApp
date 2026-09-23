namespace CoreventApp.Views;

public partial class Login : ContentPage
{
    public Login(ViewModels.LoginViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
