namespace CoreventApp.Views;

public partial class Tickets : ContentPage
{
    public Tickets(ViewModels.TicketsViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
