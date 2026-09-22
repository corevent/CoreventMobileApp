using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class Explore : ContentPage
{
	public Explore(ExploreViewModel viewModel)
	{
		InitializeComponent();
		BindingContext = viewModel;
	}
}
