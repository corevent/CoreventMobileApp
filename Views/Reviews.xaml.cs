namespace CoreventApp.Views;

public partial class Reviews : ContentPage
{
    public Reviews(ViewModels.ReviewsViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
