using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class AddBankAccount : ContentPage
{
    public AddBankAccount(AddBankAccountViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
