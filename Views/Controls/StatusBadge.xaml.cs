using CoreventApp.Models;

namespace CoreventApp.Views.Controls;

public partial class StatusBadge : ContentView
{
    public static readonly BindableProperty StatusProperty = BindableProperty.Create(
        nameof(Status), typeof(string), typeof(StatusBadge), propertyChanged: OnStatusChanged);
    public static readonly BindableProperty KindProperty = BindableProperty.Create(
        nameof(Kind), typeof(StatusKind), typeof(StatusBadge), StatusKind.Ticket, propertyChanged: OnStatusChanged);

    public static readonly BindableProperty LabelProperty = BindableProperty.Create(nameof(Label), typeof(string), typeof(StatusBadge), string.Empty);
    public static readonly BindableProperty BadgeBackgroundColorProperty = BindableProperty.Create(nameof(BadgeBackgroundColor), typeof(Color), typeof(StatusBadge), Colors.Transparent);
    public static readonly BindableProperty LabelColorProperty = BindableProperty.Create(nameof(LabelColor), typeof(Color), typeof(StatusBadge), Colors.Black);

    public StatusBadge()
    {
        InitializeComponent();
        Refresh();
    }

    public string? Status { get => (string?)GetValue(StatusProperty); set => SetValue(StatusProperty, value); }
    public StatusKind Kind { get => (StatusKind)GetValue(KindProperty); set => SetValue(KindProperty, value); }
    public string Label { get => (string)GetValue(LabelProperty); private set => SetValue(LabelProperty, value); }
    public Color BadgeBackgroundColor { get => (Color)GetValue(BadgeBackgroundColorProperty); private set => SetValue(BadgeBackgroundColorProperty, value); }
    public Color LabelColor { get => (Color)GetValue(LabelColorProperty); private set => SetValue(LabelColorProperty, value); }

    private static void OnStatusChanged(BindableObject bindable, object oldValue, object newValue) => ((StatusBadge)bindable).Refresh();

    private void Refresh()
    {
        var presentation = DomainCatalog.Status(Kind, Status);
        Label = presentation.Label;
        BadgeBackgroundColor = Color.FromArgb(presentation.BackgroundColor);
        LabelColor = Color.FromArgb(presentation.TextColor);
    }
}
