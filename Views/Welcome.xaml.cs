namespace CoreventApp.Views;

public partial class Welcome : ContentPage
{
    public Welcome(ViewModels.WelcomeViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
