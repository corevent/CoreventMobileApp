namespace CoreventApp.Views;

public partial class AddPixKey : ContentPage
{
    public AddPixKey(ViewModels.AddPixKeyViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
