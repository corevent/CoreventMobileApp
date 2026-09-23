using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class PanelOrganizer : ContentPage
{
    public PanelOrganizer(PanelOrganizerViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
