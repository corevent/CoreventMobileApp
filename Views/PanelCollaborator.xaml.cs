using CoreventApp.ViewModels;

namespace CoreventApp.Views;

public partial class PanelCollaborator : ContentPage
{
    public PanelCollaborator(PanelCollaboratorViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
        _ = viewModel.LoadCommand.ExecuteAsync(null);
    }
}
