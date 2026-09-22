namespace CoreventApp.Views;

public partial class Favorites : ContentPage
{
	public Favorites(ViewModels.FavoritesViewModel viewModel)
	{
		InitializeComponent();
		BindingContext = viewModel;
	}
}