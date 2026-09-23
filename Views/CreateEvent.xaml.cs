namespace CoreventApp.Views;

public partial class CreateEvent : ContentPage
{
    public CreateEvent(ViewModels.CreateEventViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
