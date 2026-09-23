using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class CollaboratorEventDetail : ContentPage
{
    public CollaboratorEventDetail(CollaboratorEventDetailViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
