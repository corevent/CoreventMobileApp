namespace CoreventApp.Models;

public sealed record DomainOption(string ApiValue, string Label);

public enum StatusKind
{
    Event,
    Ticket,
    Order
}

public sealed record StatusPresentation(string Label, string BackgroundColor, string TextColor);

/// <summary>Single source of truth for API values and their Portuguese presentation.</summary>
public static class DomainCatalog
{
    public static IReadOnlyList<DomainOption> Categories { get; } =
    [
        new("music", "Música"), new("tech", "Tecnologia"), new("education", "Educação"),
        new("sports", "Esportes"), new("business", "Negócios"), new("art_culture", "Arte e Cultura"),
        new("gastronomy", "Gastronomia"), new("health_wellness", "Saúde e Bem-estar"),
        new("family_kids", "Família e Crianças"), new("religious_spiritual", "Religioso/Espiritual"),
        new("games", "Jogos"), new("community_social", "Comunidade/Social"),
        new("fashion_beauty", "Moda e Beleza"), new("other", "Outro")
    ];

    public static IReadOnlyList<DomainOption> LocationTypes { get; } =
    [new("online", "Online"), new("in_person", "Presencial"), new("hybrid", "Híbrido")];

    public static IReadOnlyList<DomainOption> EventStatuses { get; } =
    [new("draft", "Rascunho"), new("opened", "Ativo"), new("going", "Em andamento"), new("canceled", "Cancelado"), new("finished", "Encerrado")];

    public static string CategoryLabel(string? value) => LabelFor(Categories, value, value ?? string.Empty);
    public static string LocationTypeLabel(string? value) => LabelFor(LocationTypes, value, "Presencial");
    public static string CategoryValue(string? label) => ValueFor(Categories, label, "other");
    public static string LocationTypeValue(string? label) => ValueFor(LocationTypes, label, "in_person");

    public static StatusPresentation Status(StatusKind kind, string? value) => (kind, value) switch
    {
        (StatusKind.Event, "draft") => new("RASCUNHO", "#F3F4F6", "#4B5563"),
        (StatusKind.Event, "opened") => new("ATIVO", "#DCFCE7", "#16A34A"),
        (StatusKind.Event, "going") => new("EM ANDAMENTO", "#DBEAFE", "#2563EB"),
        (StatusKind.Event, "canceled") => new("CANCELADO", "#FEE2E2", "#DC2626"),
        (StatusKind.Event, "finished") => new("ENCERRADO", "#F3F4F6", "#4B5563"),
        (_, "pending") => new("Pendente", "#FEF3C7", "#D97706"),
        (_, "paid") => new("Confirmado", "#DCFCE7", "#16A34A"),
        (_, "checked_in") => new("Finalizado", "#DBEAFE", "#2563EB"),
        (_, "cancelled") => new("Cancelado", "#FEE2E2", "#DC2626"),
        (StatusKind.Event, _) => new("ATIVO", "#DCFCE7", "#16A34A"),
        _ => new(value?.ToUpperInvariant() ?? "—", "#F3F4F6", "#4B5563")
    };

    private static string LabelFor(IReadOnlyList<DomainOption> options, string? value, string fallback) =>
        options.FirstOrDefault(x => x.ApiValue == value)?.Label ?? fallback;

    private static string ValueFor(IReadOnlyList<DomainOption> options, string? label, string fallback) =>
        options.FirstOrDefault(x => x.Label == label)?.ApiValue ?? fallback;
}
