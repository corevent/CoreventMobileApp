using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class Home : ContentPage
{
  public Home(HomeViewModel viewModel)
  {
    InitializeComponent();
    BindingContext = viewModel;
  }
}
